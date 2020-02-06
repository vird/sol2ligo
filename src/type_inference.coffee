config = require "./config"
Type = require "type"
require "./type_safe"
module = @

# Прим. Это система типов eth
# каждый язык, который хочет транслироваться должен сам решать как он будет преобразовывать эти типы в свои
@default_var_hash_gen = ()->
  {
    msg : (()->
      ret = new Type "struct"
      ret.field_hash.sender = new Type "address"
      ret.field_hash.value  = new Type "uint256"
      ret.field_hash.data   = new Type "bytes"
      ret
    )()
    tx : (()->
      ret = new Type "struct"
      ret.field_hash["origin"] = new Type "address"
      ret
    )()
    block : (()->
      ret = new Type "struct"
      ret.field_hash["timestamp"] = new Type "uint256"
      ret
    )()
    now     : new Type "uint256"
    require : new Type "function2_pure<function<bool>,function<>>"
    require2: new Type "function2_pure<function<bool, string>,function<>>"
    assert  : new Type "function2_pure<function<bool>,function<>>"
    revert  : new Type "function2_pure<function<string>,function<>>"
  }

array_field_hash =
  "length": new Type "uint256"
  "push"  : (type)->
    ret = new Type "function2_pure<function<>,function<>>"
    ret.nest_list[0].nest_list.push type.nest_list[0]
    ret

address_field_hash =
  "send"    : new Type "function2_pure<function2<uint256>,function2<bool>>"
  "transfer": new Type "function2_pure<function2<uint256>,function2<>>" # throws on false

@default_type_hash_gen = ()->
  ret = {
    bool    : true
    array   : true
    string  : true
    address : true
  }
  
  for type in config.any_int_type_list
    ret[type] = true
  
  ret

@bin_op_ret_type_hash_list = {
  BOOL_AND : [["bool", "bool", "bool"]]
  BOOL_OR  : [["bool", "bool", "bool"]]
}
@un_op_ret_type_hash_list = {
  BOOL_NOT : [
    ["bool", "bool"]
  ]
  BIT_NOT : []
  MINUS   : []
}

# ###################################################################################################
#    type table
# ###################################################################################################
do ()=>
  for type in config.any_int_type_list
    @un_op_ret_type_hash_list.BIT_NOT.push [type, type]
  
  for type in config.int_type_list
    @un_op_ret_type_hash_list.MINUS.push [type, type]
    
  for v in "ADD SUB MUL POW".split  /\s+/g
    @bin_op_ret_type_hash_list[v] = list = []
    for type in config.uint_type_list
      list.push [type, type, type]
    
  for v in "BIT_AND BIT_OR".split  /\s+/g
    @bin_op_ret_type_hash_list[v] = list = []
    for type in config.uint_type_list
      list.push [type, type, type]
  
  for v in "EQ NE GT LT GTE LTE".split  /\s+/g
    @bin_op_ret_type_hash_list[v] = list = []
    for type in config.any_int_type_list
      list.push [type, type, "bool"]
  
  # special
  for v in "SHL SHR".split  /\s+/g
    @bin_op_ret_type_hash_list[v] = list = []
    for type_main in config.uint_type_list
      for type_index in config.uint_type_list
        list.push [type_main, type_index, type_main]
  
  return

# ###################################################################################################

class Ti_context
  parent    : null
  parent_fn : null
  current_class : null
  var_hash  : {}
  type_hash : {}
  
  constructor:()->
    @var_hash = module.default_var_hash_gen()
    @type_hash= module.default_type_hash_gen()
  
  mk_nest : ()->
    ret = new Ti_context
    ret.parent = @
    ret.parent_fn = @parent_fn
    ret.current_class = @current_class
    obj_set ret.type_hash, @type_hash
    ret
  
  type_proxy : (cls)->
    ret = new Type "struct"
    for k,v of cls._prepared_field2type
      continue unless v.main in ["function2", "function2_pure"]
      ret.field_hash[k] = v
    ret
  
  check_id : (id)->
    if id == "this"
      return @type_proxy @current_class
    if type_decl = @type_hash[id]
      return @type_proxy type_decl
    return ret if ret = @var_hash[id]
    if state_class = @type_hash[config.storage]
      return ret if ret = state_class._prepared_field2type[id]
    
    if @parent
      return @parent.check_id id
    throw new Error "can't find decl for id '#{id}'"
  
  check_type : (_type)->
    return ret if ret = @type_hash[_type]
    if @parent
      return @parent.check_type _type
    throw new Error "can't find type '#{_type}'"

class_prepare = (root, ctx)->
  ctx.type_hash[root.name] = root
  for v in root.scope.list
    switch v.constructor.name
      when "Var_decl"
        root._prepared_field2type[v.name] = v.type
      
      when "Fn_decl_multiret"
        # BUG внутри scope уже есть this и ему нужен тип...
        if v.state_mutability == "pure"
          type = new Type "function2_pure<function,function>"
        else
          type = new Type "function2<function,function>"
        type.nest_list[0] = v.type_i
        type.nest_list[1] = v.type_o
        root._prepared_field2type[v.name] = type
  
  return

is_not_a_type = (type)->
  !type or type.main == "number"

is_composite_type = (type)->
  type.main in ["array", "tuple", "map", "struct"]

is_defined_number_type = (type)->
  # TODO better check
  /^u?int\d{0,3}$/.test type.main
  

@gen = (ast_tree, opt)->
  change_count = 0
  type_spread_left = (a_type, b_type, touch_counter=true)->
    return a_type if !b_type
    if !a_type and b_type
      a_type = b_type.clone()
      change_count++ if touch_counter
    else if is_not_a_type(a_type) and !is_not_a_type(b_type)
      if a_type.main == "number"
        unless is_defined_number_type b_type
          throw new Error "can't spread '#{b_type}' to '#{a_type}'"
      else
        throw new Error "unknown is_not_a_type spread case"
      a_type = b_type.clone()
      change_count++ if touch_counter
    else if !is_not_a_type(a_type) and is_not_a_type(b_type)
      # will check, but not spread
      if b_type.main == "number"
        unless is_defined_number_type a_type
          throw new Error "can't spread '#{b_type}' to '#{a_type}'. Reverse spread collision detected"
      # p "NOTE Reverse spread collision detected", new Error "..."
    else
      return a_type if a_type.cmp b_type
      
      if is_composite_type a_type
        if !is_composite_type b_type
          throw new Error "can't spread between '#{a_type}' '#{b_type}'. Reason: is_composite_type mismatch"
        # composite
        if a_type.main != b_type.main
          throw new Error "spread composite collision '#{a_type}' '#{b_type}'. Reason: composite container mismatch"
        
        if a_type.nest_list.length != b_type.nest_list.length
          throw new Error "spread composite collision '#{a_type}' '#{b_type}'. Reason: nest_list length mismatch"
        
        for idx in [0 ... a_type.nest_list.length]
          inner_a = a_type.nest_list[idx]
          inner_b = b_type.nest_list[idx]
          new_inner_a = type_spread_left inner_a, inner_b, touch_counter
          a_type.nest_list[idx] = new_inner_a
        
        # TODO struct? but we don't need it? (field_hash)
      else
        if is_composite_type b_type
          throw new Error "can't spread between '#{a_type}' '#{b_type}'. Reason: is_composite_type mismatch"
        # scalar
        throw new Error "spread scalar collision '#{a_type}' '#{b_type}'. Reason: type mismatch"
    
    return a_type
  
  # phase 1 bottom-to-top walk + type reference
  walk = (root, ctx)->
    switch root.constructor.name
      # ###################################################################################################
      #    expr
      # ###################################################################################################
      when "Var"
        root.type = type_spread_left root.type, ctx.check_id root.name
      
      when "Const"
        root.type
      
      when "Bin_op"
        list = module.bin_op_ret_type_hash_list[root.op]
        a = (walk(root.a, ctx) or "").toString()
        b = (walk(root.b, ctx) or "").toString()
        
        found = false
        if list
          for tuple in list
            continue if tuple[0] != a
            continue if tuple[1] != b
            found = true
            root.type = type_spread_left root.type, new Type tuple[2]
        
        # extra cases
        if !found
          # may produce invalid result
          if root.op == "ASSIGN"
            root.type = type_spread_left root.type, root.a.type
            found = true
          else if root.op in ["EQ", "NE"]
            root.type = type_spread_left root.type, new Type "bool"
            found = true
          else if root.op == "INDEX_ACCESS"
            switch root.a.type.main
              when "string"
                root.type = type_spread_left root.type, new Type "string"
                found = true
              
              when "map"
                key = root.a.type.nest_list[0]
                if is_not_a_type root.b.type
                  root.b.type = type_spread_left root.b.type, key
                else if !key.cmp root.b.type
                  throw new Error("bad index access to '#{root.a.type}' with index '#{root.b.type}'")
                root.type = type_spread_left root.type, root.a.type.nest_list[1]
                found = true
              
              when "array"
                root.type = type_spread_left root.type, root.a.type.nest_list[0]
                found = true
              
              # when "hash"
                # root.type = type_spread_left root.type, root.a.type.nest_list[0]
                # found = true
              # when "hash_int"
                # root.type = type_spread_left root.type, root.a.type.nest_list[0]
                # found = true
        
        # NOTE only fire warning on bruteforce fail
        # if !found
          # perr "unknown bin_op=#{root.op} a=#{a} b=#{b}"
          # throw new Error "unknown bin_op=#{root.op} a=#{a} b=#{b}"
        root.type
      
      when "Un_op"
        list = module.un_op_ret_type_hash_list[root.op]
        a = walk(root.a, ctx)
        
        found = false
        if list
          a_main = a?.main
          for tuple in list
            if a
              continue if tuple[0] != a_main
            found = true
            root.type = type_spread_left root.type, new Type tuple[1]
            break
          
          if !found and is_not_a_type a
            uint_candidate_list = []
            for tuple in list
              continue if !config.uint_type_list.has tuple[0]
              uint_candidate_list.push tuple[1]
            
            int_candidate_list = []
            for tuple in list
              continue if !config.int_type_list.has tuple[0]
              int_candidate_list.push tuple[1]
            
            can_be_int  = int_candidate_list.length > 0
            can_be_uint = uint_candidate_list.length > 0
            
            if can_be_int and can_be_uint
              "skip"
              # p "NOTE can_be_int and can_be_uint"
            else if can_be_int and !can_be_uint
              found = true
              if int_candidate_list.length == 1
                root.type = type_spread_left root.type, new Type int_candidate_list[0]
              # else
                # p "NOTE multiple int_candidate_list"
            else if !can_be_int and can_be_uint
              found = true
              if uint_candidate_list.length == 1
                root.type = type_spread_left root.type, new Type uint_candidate_list[0]
              # else
                # p "NOTE multiple uint_candidate_list"
        
        if !found
          if root.op == "DELETE"
            if root.a.constructor.name == "Bin_op"
              if root.a.op == "INDEX_ACCESS"
                if root.a.a.type?.main == "array"
                  return
                if root.a.a.type?.main == "map"
                  return
        if !found and a
          throw new Error "unknown un_op=#{root.op} a=#{a}"
        root.type
      
      when "Field_access"
        root_type = walk(root.t, ctx)
        
        switch root_type.main
          when "array"
            field_hash = array_field_hash
          
          when "address"
            field_hash = address_field_hash
          
          when "struct"
            field_hash = root_type.field_hash
          
          else
            class_decl = ctx.check_type root_type.main
            field_hash = class_decl._prepared_field2type
        
        if !field_type = field_hash[root.name]
          perr root.t
          perr field_hash
          throw new Error "unknown field. '#{root.name}' at type '#{root_type}'. Allowed fields [#{Object.keys(field_hash).join ', '}]"
        
        # Я не понял зачем это
        # field_type = ast.type_actualize field_type, root.t.type
        if typeof field_type == "function"
          field_type = field_type root.t.type
        
        root.type = type_spread_left root.type, field_type
        root.type
      
      when "Fn_call"
        root_type = walk root.fn, ctx
        
        if root_type.main == "function2_pure"
          offset = 0
        else
          offset = 2
        
        for arg in root.arg_list
          walk arg, ctx
        root.type = type_spread_left root.type, root_type.nest_list[1].nest_list[offset]
      
      # ###################################################################################################
      #    stmt
      # ###################################################################################################
      when "Comment"
        null
      
      when "Var_decl"
        if root.assign_value
          root.assign_value.type = type_spread_left root.assign_value.type, root.type
          walk root.assign_value, ctx
        ctx.var_hash[root.name] = root.type
        null
      
      when "Throw"
        if root.t
          walk root.t, ctx
        null
      
      when "Scope"
        ctx_nest = ctx.mk_nest()
        for v in root.list
          if v.constructor.name == "Class_decl"
            class_prepare v, ctx
        for v in root.list
          walk v, ctx_nest
        
        null
      
      when "Ret_multi"
        for v,idx in root.t_list
          if is_not_a_type v.type
            v.type = type_spread_left v.type, ctx.parent_fn.type_o.nest_list[idx]
          else
            expected = ctx.parent_fn.type_o.nest_list[idx]
            real = v.type
            if !expected.cmp real
              perr root
              perr "fn_type=#{ctx.parent_fn.type_o}"
              perr v
              throw new Error "Ret_multi type mismatch [#{idx}] expected=#{expected} real=#{real} @fn=#{ctx.parent_fn.name}"
          
          walk v, ctx
        null
      
      when "Class_decl"
        class_prepare root, ctx
        
        ctx_nest = ctx.mk_nest()
        ctx_nest.current_class = root
        
        for k,v of root._prepared_field2type
          ctx_nest.var_hash[k] = v
        
        # ctx_nest.var_hash["this"] = new Type root.name
        walk root.scope, ctx_nest
        root.type
      
      when "Fn_decl_multiret"
        if root.state_mutability == "pure"
          complex_type = new Type "function2_pure"
        else
          complex_type = new Type "function2"
        complex_type.nest_list.push root.type_i
        complex_type.nest_list.push root.type_o
        ctx.var_hash[root.name] = complex_type
        ctx_nest = ctx.mk_nest()
        ctx_nest.parent_fn = root
        for name,k in root.arg_name_list
          type = root.type_i.nest_list[k]
          ctx_nest.var_hash[name] = type
        walk root.scope, ctx_nest
        root.type
      
      when "PM_switch"
        null
      
      # ###################################################################################################
      #    control flow
      # ###################################################################################################
      when "If"
        walk(root.cond, ctx)
        walk(root.t, ctx.mk_nest())
        walk(root.f, ctx.mk_nest())
        null
      
      when "While"
        walk root.cond, ctx.mk_nest()
        walk root.scope, ctx.mk_nest()
        null
      
      when "Enum_decl"
        null
      
      when "Type_cast"
        root.type
      
      when "Ternary"
        root.type
      
      when "New"
        root.type
      
      when "Tuple"
        for v in root.list
          walk v, ctx
        
        # -> ret
        nest_list = []
        for v in root.list
          nest_list.push v.type
        
        type = new Type "tuple<>"
        type.nest_list = nest_list
        root.type = type_spread_left root.type, type
        
        # <- ret
        
        for v,idx in root.type.nest_list
          tuple_value = root.list[idx]
          tuple_value.type = type_spread_left tuple_value.type, v
        
        root.type
      
      when "Array_init"
        for v in root.list
          walk v, ctx
        
        nest_type = null
        if root.type
          if root.type.main != "array"
            throw new Error "Array_init can have only array type"
          nest_type = root.type.nest_list[0]
        
        for v in root.list
          nest_type = type_spread_left nest_type, v.type
        
        for v in root.list
          v.type = type_spread_left v.type, nest_type
        
        type = new Type "array<#{nest_type}>"
        root.type = type_spread_left root.type, type
        root.type
      
      else
        ### !pragma coverage-skip-block ###
        perr root
        throw new Error "ti phase 1 unknown node '#{root.constructor.name}'"
  walk ast_tree, new Ti_context
  
  # phase 2
  # iterable
  
  # TODO refactor. Stage 2 should reuse code from stage 1 but override some branches
  # Прим. спорно. В этом случае надо будет как-то информировать что это phase 2 иначе будет непонятно что привело к этому
  # возможно копипастить меньшее зло, чем потом дебажить непонятно как (т.к. сейчас p можно поставить на stage 1 и stage 2 раздельно)
  walk = (root, ctx)->
    switch root.constructor.name
      # ###################################################################################################
      #    expr
      # ###################################################################################################
      when "Var"
        root.type = type_spread_left root.type, ctx.check_id root.name
      
      when "Const"
        root.type
      
      when "Bin_op"
        bruteforce_a = is_not_a_type root.a.type
        bruteforce_b = is_not_a_type root.b.type
        if bruteforce_a or bruteforce_b
          list = module.bin_op_ret_type_hash_list[root.op]
          can_bruteforce = root.type?
          can_bruteforce and= bruteforce_a or bruteforce_b
          can_bruteforce and= list?
          
          switch root.op
            when "ASSIGN"
              if bruteforce_a and !bruteforce_b
                root.a.type = type_spread_left root.a.type, root.b.type
              else if !bruteforce_a and bruteforce_b
                root.b.type = type_spread_left root.b.type, root.a.type
            
            when "INDEX_ACCESS"
              # NOTE we can't infer type of a for now
              if !bruteforce_a and bruteforce_b
                switch root.a.type?.main
                  when "array"
                    root.b.type = type_spread_left root.b.type, new Type "uint256"
                  
                  when "map"
                    root.b.type = type_spread_left root.b.type, root.a.type.nest_list[0]
                  
                  else
                    perr "can't type inference INDEX_ACCESS for #{root.a.type}"
            
            else
              if !list?
                perr "can't type inference bin_op='#{root.op}'"
          
          if can_bruteforce
            a_type_list = if bruteforce_a then [] else [root.a.type.toString()]
            b_type_list = if bruteforce_b then [] else [root.b.type.toString()]
            
            refined_list = []
            cmp_ret_type = root.type.toString()
            for v in list
              continue if cmp_ret_type != v[2]
              a_type_list.push v[0] if bruteforce_a
              b_type_list.push v[1] if bruteforce_b
              refined_list.push v
            
            candidate_list = []
            for a_type in a_type_list
              for b_type in b_type_list
                for pair in refined_list
                  [cmp_a_type, cmp_b_type] = pair
                  continue if a_type != cmp_a_type
                  continue if b_type != cmp_b_type
                  candidate_list.push pair
            
            if candidate_list.length == 1
              [a_type, b_type] = candidate_list[0]
              root.a.type = type_spread_left root.a.type, new Type a_type
              root.b.type = type_spread_left root.b.type, new Type b_type
            # else
              # p "candidate_list=#{candidate_list.length}"
        
        walk(root.a, ctx)
        walk(root.b, ctx)
        root.type
      
      when "Un_op"
        list = module.un_op_ret_type_hash_list[root.op]
        a = walk(root.a, ctx)
        
        found = false
        if list
          a_main = a?.main
          for tuple in list
            if a
              continue if tuple[0] != a_main
            found = true
            root.type = type_spread_left root.type, new Type tuple[1]
            break
          
          if !found and is_not_a_type a
            uint_candidate_list = []
            for tuple in list
              continue if !config.uint_type_list.has tuple[0]
              uint_candidate_list.push tuple[1]
            
            int_candidate_list = []
            for tuple in list
              continue if !config.int_type_list.has tuple[0]
              int_candidate_list.push tuple[1]
            
            can_be_int  = int_candidate_list.length > 0
            can_be_uint = uint_candidate_list.length > 0
            
            if can_be_int and can_be_uint
              "skip"
              # p "NOTE can_be_int and can_be_uint"
            else if can_be_int and !can_be_uint
              found = true
              if int_candidate_list.length == 1
                root.type = type_spread_left root.type, new Type int_candidate_list[0]
              # else
                # p "NOTE multiple int_candidate_list"
            else if !can_be_int and can_be_uint
              found = true
              if uint_candidate_list.length == 1
                root.type = type_spread_left root.type, new Type uint_candidate_list[0]
              # else
                # p "NOTE multiple uint_candidate_list"
        
        if !found
          if root.op == "DELETE"
            if root.a.constructor.name == "Bin_op"
              if root.a.op == "INDEX_ACCESS"
                if root.a.a.type?.main == "array"
                  return
                if root.a.a.type?.main == "map"
                  return
        if !found and a
          throw new Error "unknown un_op=#{root.op} a=#{a}"
        root.type
      
      when "Field_access"
        root_type = walk(root.t, ctx)
        
        switch root_type.main
          when "array"
            field_hash = array_field_hash
          
          when "address"
            field_hash = address_field_hash
          
          when "struct"
            field_hash = root_type.field_hash
          
          else
            class_decl = ctx.check_type root_type.main
            field_hash = class_decl._prepared_field2type
        
        if !field_type = field_hash[root.name]
          throw new Error "unknown field. '#{root.name}' at type '#{root_type}'. Allowed fields [#{Object.keys(field_hash).join ', '}]"
        
        # Я не понял зачем это
        # field_type = ast.type_actualize field_type, root.t.type
        if typeof field_type == "function"
          field_type = field_type root.t.type
        root.type = type_spread_left root.type, field_type
        root.type
      
      when "Fn_call"
        root_type = walk root.fn, ctx
        
        if root_type.main == "function2_pure"
          offset = 0
        else
          offset = 2
        
        for arg,i in root.arg_list
          walk arg, ctx
          expected_type = root_type.nest_list[0].nest_list[i+offset]
          arg.type = type_spread_left arg.type, expected_type
        root.type = type_spread_left root.type, root_type.nest_list[1].nest_list[offset]
      
      # ###################################################################################################
      #    stmt
      # ###################################################################################################
      when "Comment"
        null
      
      when "Var_decl"
        if root.assign_value
          root.assign_value.type = type_spread_left root.assign_value.type, root.type
          walk root.assign_value, ctx
        ctx.var_hash[root.name] = root.type
        null
      
      when "Throw"
        if root.t
          walk root.t, ctx
        null
      
      when "Scope"
        ctx_nest = ctx.mk_nest()
        for v in root.list
          walk v, ctx_nest
        
        null
      
      when "Ret_multi"
        for v,idx in root.t_list
          if is_not_a_type v.type
            v.type = type_spread_left v.type, ctx.parent_fn.type_o.nest_list[idx]
          else
            expected = ctx.parent_fn.type_o.nest_list[idx]
            real = v.type
            if !expected.cmp real
              perr root
              perr "fn_type=#{ctx.parent_fn.type_o}"
              perr v
              throw new Error "Ret_multi type mismatch [#{idx}] expected=#{expected} real=#{real} @fn=#{ctx.parent_fn.name}"
          
          walk v, ctx
        null
      
      when "Class_decl"
        class_prepare root, ctx
        
        ctx_nest = ctx.mk_nest()
        ctx_nest.current_class = root
        
        for k,v of root._prepared_field2type
          ctx_nest.var_hash[k] = v
        
        # ctx_nest.var_hash["this"] = new Type root.name
        walk root.scope, ctx_nest
        root.type
      
      when "Fn_decl_multiret"
        if root.state_mutability == "pure"
          complex_type = new Type "function2_pure"
        else
          complex_type = new Type "function2"
        complex_type.nest_list.push root.type_i
        complex_type.nest_list.push root.type_o
        ctx.var_hash[root.name] = complex_type
        ctx_nest = ctx.mk_nest()
        ctx_nest.parent_fn = root
        for name,k in root.arg_name_list
          type = root.type_i.nest_list[k]
          ctx_nest.var_hash[name] = type
        walk root.scope, ctx_nest
        root.type
      
      when "PM_switch"
        null
      
      # ###################################################################################################
      #    control flow
      # ###################################################################################################
      when "If"
        walk(root.cond, ctx)
        walk(root.t, ctx.mk_nest())
        walk(root.f, ctx.mk_nest())
        null
      
      when "While"
        walk root.cond, ctx.mk_nest()
        walk root.scope, ctx.mk_nest()
        null
      
      when "Enum_decl"
        null
      
      when "Type_cast"
        root.type
      
      when "Ternary"
        root.type
      
      when "New"
        root.type
      
      when "Tuple"
        for v in root.list
          walk v, ctx
        
        # -> ret
        nest_list = []
        for v in root.list
          nest_list.push v.type
        
        type = new Type "tuple<>"
        type.nest_list = nest_list
        root.type = type_spread_left root.type, type
        
        # <- ret
        
        for v,idx in root.type.nest_list
          tuple_value = root.list[idx]
          tuple_value.type = type_spread_left tuple_value.type, v
        
        root.type
      
      when "Array_init"
        for v in root.list
          walk v, ctx
        
        nest_type = null
        if root.type
          if root.type.main != "array"
            throw new Error "Array_init can have only array type"
          nest_type = root.type.nest_list[0]
        
        for v in root.list
          nest_type = type_spread_left nest_type, v.type
        
        for v in root.list
          v.type = type_spread_left v.type, nest_type
        
        type = new Type "array<#{nest_type}>"
        root.type = type_spread_left root.type, type
        root.type
      
      else
        ### !pragma coverage-skip-block ###
        perr root
        throw new Error "ti phase 2 unknown node '#{root.constructor.name}'"
  
  change_count = 0
  for i in [0 ... 100] # prevent infinite
    walk ast_tree, new Ti_context
    # p "phase 2 ti change_count=#{change_count}" # DEBUG
    break if change_count == 0
    change_count = 0
  
  ast_tree
