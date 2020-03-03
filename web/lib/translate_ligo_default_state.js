(function() {
  var Type, config, last_bracket_state, module, translate_type, type2default_value, walk, _ref;

  module = this;

  

  config = window.config

  Type = window.Type

  _ref = translate_ligo, translate_type = _ref.translate_type, type2default_value = _ref.type2default_value;

  this.Gen_context = (function() {
    Gen_context.prototype.next_gen = null;

    Gen_context.prototype.var_hash = {};

    Gen_context.prototype.contract_hash = {};

    Gen_context.prototype.type_decl_hash = {};

    function Gen_context() {
      this.var_hash = {};
      this.contract_hash = {};
      this.type_decl_hash = {};
    }

    Gen_context.prototype.mk_nest_contract = function(name) {
      var t;
      t = new module.Gen_context;
      this.contract_hash[name] = t.var_hash;
      obj_set(t.type_decl_hash, this.type_decl_hash);
      return t;
    };

    return Gen_context;

  })();

  last_bracket_state = false;

  walk = function(root, ctx) {
    var v, _i, _len, _ref1;
    last_bracket_state = false;
    switch (root.constructor.name) {
      case "Scope":
        _ref1 = root.list;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          v = _ref1[_i];
          walk(v, ctx);
        }
        return "nothing";
      case "Comment":
      case "Fn_decl_multiret":
      case "Enum_decl":
        return "nothing";
      case "Var_decl":
        ctx.var_hash[root.name] = {
          type: translate_type(root.type, ctx),
          value: type2default_value(root.type, ctx)
        };
        return "nothing";
      case "Class_decl":
        if (root.need_skip) {
          return;
        }
        ctx.type_decl_hash[root.name] = root;
        if (root.is_contract) {
          ctx = ctx.mk_nest_contract(root.name);
        }
        return walk(root.scope, ctx);
      case "Enum_decl":
        ctx.type_decl_hash[root.name] = root;
        return "nothing";
      default:
        if (ctx.next_gen != null) {
          return ctx.next_gen(root, ctx);
        } else {
          perr(root);
          throw new Error("Unknown root.constructor.name " + root.constructor.name);
        }
    }
  };

  this.gen = function(root, opt) {
    var contract, ctx, field_jl, jl, k, type, v, var_content, var_name, _ref1, _ref2;
    if (opt == null) {
      opt = {};
    }
    if (opt.convert_to_string == null) {
      opt.convert_to_string = true;
    }
    ctx = new module.Gen_context;
    ctx.next_gen = opt.next_gen;
    walk(root, ctx);
    _ref1 = ctx.contract_hash;
    for (k in _ref1) {
      v = _ref1[k];
      if (0 === h_count(v)) {
        type = new Type("uint");
        v[config.empty_state] = {
          type: translate_type(type, ctx),
          value: type2default_value(type, ctx)
        };
      }
    }
    if (!opt.convert_to_string) {
      return ctx.contract_hash;
    }
    jl = [];
    _ref2 = ctx.contract_hash;
    for (k in _ref2) {
      contract = _ref2[k];
      field_jl = [];
      for (var_name in contract) {
        var_content = contract[var_name];
        field_jl.push("" + var_name + " = " + var_content.value + ";");
      }
      jl.push("record\n  " + (join_list(field_jl, '  ')) + "\nend");
    }
    return join_list(jl, '');
  };

}).call(window.translate_ligo_default_state = {});
