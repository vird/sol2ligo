(function() {
  var Type, ast, check_external_ops, config, module, translate_type, translate_var_name, tweak_translate_var_name;

  module = this;

  Type = window.Type

  config = window.config

  ast = window.mod_ast;

  translate_var_name = window.translate_var_name.translate_var_name;

  translate_type = window.translate_type;

  (function(_this) {
    return (function() {
      var out_walk;
      out_walk = function(root, ctx) {
        var idx, v, walk, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _ref, _ref1, _ref2, _ref3, _ref4;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Scope":
            _ref = root.list;
            for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
              v = _ref[idx];
              root.list[idx] = walk(v, ctx);
            }
            return root;
          case "Var":
          case "Const":
            return root;
          case "Un_op":
            root.a = walk(root.a, ctx);
            return root;
          case "Bin_op":
            root.a = walk(root.a, ctx);
            root.b = walk(root.b, ctx);
            return root;
          case "Field_access":
            root.t = walk(root.t, ctx);
            return root;
          case "Fn_call":
            root.fn = walk(root.fn, ctx);
            _ref1 = root.arg_list;
            for (idx = _j = 0, _len1 = _ref1.length; _j < _len1; idx = ++_j) {
              v = _ref1[idx];
              root.arg_list[idx] = walk(v, ctx);
            }
            return root;
          case "Struct_init":
            root.fn = root.fn;
            if (ctx.class_hash && root.arg_names.length === 0) {
              _ref2 = ctx.class_hash[root.fn.name].scope.list;
              for (idx = _k = 0, _len2 = _ref2.length; _k < _len2; idx = ++_k) {
                v = _ref2[idx];
                root.arg_names.push(v.name);
              }
            }
            return root;
          case "New":
            _ref3 = root.arg_list;
            for (idx = _l = 0, _len3 = _ref3.length; _l < _len3; idx = ++_l) {
              v = _ref3[idx];
              root.arg_list[idx] = walk(v, ctx);
            }
            return root;
          case "Comment":
            return root;
          case "Continue":
          case "Break":
            return root;
          case "Var_decl":
            if (root.assign_value) {
              root.assign_value = walk(root.assign_value, ctx);
            }
            return root;
          case "Var_decl_multi":
            if (root.assign_value) {
              root.assign_value = walk(root.assign_value, ctx);
            }
            return root;
          case "Throw":
            if (root.t) {
              walk(root.t, ctx);
            }
            return root;
          case "Enum_decl":
          case "Type_cast":
          case "Tuple":
            return root;
          case "Ret_multi":
            _ref4 = root.t_list;
            for (idx = _m = 0, _len4 = _ref4.length; _m < _len4; idx = ++_m) {
              v = _ref4[idx];
              root.t_list[idx] = walk(v, ctx);
            }
            return root;
          case "If":
          case "Ternary":
            root.cond = walk(root.cond, ctx);
            root.t = walk(root.t, ctx);
            root.f = walk(root.f, ctx);
            return root;
          case "While":
            root.cond = walk(root.cond, ctx);
            root.scope = walk(root.scope, ctx);
            return root;
          case "For3":
            if (root.init) {
              root.init = walk(root.init, ctx);
            }
            if (root.cond) {
              root.cond = walk(root.cond, ctx);
            }
            if (root.iter) {
              root.iter = walk(root.iter, ctx);
            }
            root.scope = walk(root.scope, ctx);
            return root;
          case "Class_decl":
            root.scope = walk(root.scope, ctx);
            return root;
          case "Fn_decl_multiret":
            root.scope = walk(root.scope, ctx);
            return root;
          case "Tuple":
          case "Array_init":
            return root;
          case "Event_decl":
            return root;
          default:

            /* !pragma coverage-skip-block */
            perr(root);
            throw new Error("unknown root.constructor.name " + root.constructor.name);
        }
      };
      return module.default_walk = out_walk;
    });
  })(this)();

  tweak_translate_var_name = function(name) {
    if (name === config.contract_storage) {
      return translate_var_name(name);
    } else {
      return name;
    }
  };

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var idx, name, _i, _j, _len, _len1, _ref, _ref1, _var;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Var":
            root.name = tweak_translate_var_name(root.name);
            return root;
          case "Var_decl":
            if (root.assign_value) {
              root.assign_value = walk(root.assign_value, ctx);
            }
            root.name = tweak_translate_var_name(root.name);
            return root;
          case "Var_decl_multi":
            if (root.assign_value) {
              root.assign_value = walk(root.assign_value, ctx);
            }
            _ref = root.list;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              _var = _ref[_i];
              _var.name = tweak_translate_var_name(_var.name);
            }
            return root;
          case "Fn_decl_multiret":
            root.scope = walk(root.scope, ctx);
            _ref1 = root.arg_name_list;
            for (idx = _j = 0, _len1 = _ref1.length; _j < _len1; idx = ++_j) {
              name = _ref1[idx];
              root.arg_name_list[idx] = tweak_translate_var_name(name);
            }
            return root;
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.var_translate = function(root) {
        return walk(root, {
          walk: walk,
          next_gen: module.default_walk
        });
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Fn_call":
            if (root.fn.constructor.name === "Var") {
              if (root.fn.name === "require") {
                if (root.arg_list.length === 2) {
                  root.fn.name = "require2";
                }
              }
            }
            return ctx.next_gen(root, ctx);
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.require_distinguish = function(root) {
        return walk(root, {
          walk: walk,
          next_gen: module.default_walk
        });
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var args, ret;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Event_decl":
            ctx.emit_decl_hash[root.name] = true;
            return root;
          case "Fn_call":
            if (root.fn.constructor.name === "Var") {
              if (ctx.emit_decl_hash.hasOwnProperty(root.fn.name)) {
                perr("WARNING EmitStatement is not supported. Read more: https://github.com/madfish-solutions/sol2ligo/wiki/Known-issues#solidity-events");
                ret = new ast.Comment;
                args = root.arg_list.map(function(arg) {
                  return arg.name;
                });
                ret.text = "EmitStatement " + root.fn.name + "(" + (args.join(", ")) + ")";
                return ret;
              }
            }
            return ctx.next_gen(root, ctx);
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.fix_missing_emit = function(root) {
        return walk(root, {
          walk: walk,
          next_gen: module.default_walk,
          emit_decl_hash: {}
        });
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var mod, _i, _len, _ref;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Fn_decl_multiret":
            _ref = root.modifier_list;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              mod = _ref[_i];
              walk(mod, ctx);
            }
            return ctx.next_gen(root, ctx);
          case "Fn_call":
            switch (root.fn.constructor.name) {
              case "Var":
                ctx.fn_hash[root.fn.name] = true;
                break;
              case "Field_access":
                if (root.fn.t.constructor.name === "Var") {
                  if (root.fn.t.name === "this") {
                    ctx.fn_hash[root.fn.name] = true;
                  }
                }
            }
            return ctx.next_gen(root, ctx);
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.collect_fn_call = function(root) {
        var fn_hash;
        fn_hash = {};
        walk(root, {
          walk: walk,
          next_gen: module.default_walk,
          fn_hash: fn_hash
        });
        return fn_hash;
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var change_count, clone_fn_dep_hash_hash, fn, fn_decl, fn_dep_hash_hash, fn_hash, fn_left_name_list, fn_list, fn_move_list, fn_name, fn_use_hash, fn_use_refined_hash, i, idx, k, min_idx, move_entity, name, old_idx, retry_count, use_list, v, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _len5, _m, _n, _o, _p, _ref;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Class_decl":
            for (retry_count = _i = 0; _i < 5; retry_count = ++_i) {
              if (retry_count) {
                perr("NOTE method reorder requires additional attempt retry_count=" + retry_count + ". That's not good, but we try resolve that");
              }
              fn_list = [];
              _ref = root.scope.list;
              for (_j = 0, _len = _ref.length; _j < _len; _j++) {
                v = _ref[_j];
                if (v.constructor.name !== "Fn_decl_multiret") {
                  continue;
                }
                fn_list.push(v);
              }
              fn_hash = {};
              for (_k = 0, _len1 = fn_list.length; _k < _len1; _k++) {
                fn = fn_list[_k];
                fn_hash[fn.name] = fn;
              }
              fn_dep_hash_hash = {};
              for (_l = 0, _len2 = fn_list.length; _l < _len2; _l++) {
                fn = fn_list[_l];
                fn_use_hash = module.collect_fn_call(fn);
                fn_use_refined_hash = {};
                for (k in fn_use_hash) {
                  v = fn_use_hash[k];
                  if (!fn_hash.hasOwnProperty(k)) {
                    continue;
                  }
                  fn_use_refined_hash[k] = v;
                }
                if (fn_use_refined_hash.hasOwnProperty(fn.name)) {
                  delete fn_use_refined_hash[fn.name];
                  perr("CRITICAL WARNING we found that function " + fn.name + " has self recursion. This will produce uncompileable target. Read more: https://github.com/madfish-solutions/sol2ligo/wiki/Known-issues#self-recursion--function-calls");
                }
                fn_dep_hash_hash[fn.name] = fn_use_refined_hash;
              }
              clone_fn_dep_hash_hash = deep_clone(fn_dep_hash_hash);
              fn_move_list = [];
              for (i = _m = 0; _m < 100; i = ++_m) {
                change_count = 0;
                fn_left_name_list = Object.keys(clone_fn_dep_hash_hash);
                for (_n = 0, _len3 = fn_left_name_list.length; _n < _len3; _n++) {
                  fn_name = fn_left_name_list[_n];
                  if (0 === h_count(clone_fn_dep_hash_hash[fn_name])) {
                    change_count++;
                    use_list = [];
                    delete clone_fn_dep_hash_hash[fn_name];
                    for (k in clone_fn_dep_hash_hash) {
                      v = clone_fn_dep_hash_hash[k];
                      if (v[fn_name]) {
                        delete v[fn_name];
                        use_list.push(k);
                      }
                    }
                    if (use_list.length) {
                      fn_move_list.push({
                        fn_name: fn_name,
                        use_list: use_list
                      });
                    }
                  }
                }
                if (change_count === 0) {
                  break;
                }
              }
              if (0 !== h_count(clone_fn_dep_hash_hash)) {
                perr(clone_fn_dep_hash_hash);
                perr("CRITICAL WARNING Can't reorder methods. Loop detected. This will produce uncompileable target. Read more: https://github.com/madfish-solutions/sol2ligo/wiki/Known-issues#self-recursion--function-calls");
                break;
              }
              if (fn_move_list.length === 0) {
                break;
              }
              fn_move_list.reverse();
              change_count = 0;
              for (_o = 0, _len4 = fn_move_list.length; _o < _len4; _o++) {
                move_entity = fn_move_list[_o];
                fn_name = move_entity.fn_name, use_list = move_entity.use_list;
                min_idx = Infinity;
                for (_p = 0, _len5 = use_list.length; _p < _len5; _p++) {
                  name = use_list[_p];
                  fn = fn_hash[name];
                  idx = root.scope.list.idx(fn);
                  min_idx = Math.min(min_idx, idx);
                }
                fn_decl = fn_hash[fn_name];
                old_idx = root.scope.list.idx(fn_decl);
                if (old_idx > min_idx) {
                  change_count++;
                  root.scope.list.remove_idx(old_idx);
                  root.scope.list.insert_after(min_idx - 1, fn_decl);
                }
              }
              if (change_count === 0) {
                break;
              }
            }
            return ctx.next_gen(root, ctx);
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.fix_modifier_order = function(root) {
        return walk(root, {
          walk: walk,
          next_gen: module.default_walk
        });
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var ret, while_inside;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "For3":
            ret = new ast.Scope;
            ret.need_nest = false;
            if (root.init) {
              ret.list.push(root.init);
            }
            while_inside = new ast.While;
            if (root.cond) {
              while_inside.cond = root.cond;
            } else {
              while_inside.cond = new ast.Const;
              while_inside.cond.val = "true";
              while_inside.cond.type = new Type("bool");
            }
            while_inside.scope.list.append(root.scope.list);
            if (root.iter) {
              while_inside.scope.list.push(root.iter);
            }
            ret.list.push(while_inside);
            return ret;
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.for3_unpack = function(root) {
        return walk(root, {
          walk: walk,
          next_gen: module.default_walk
        });
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var ext, reg_ret;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Bin_op":
            if (reg_ret = /^ASS_(.*)/.exec(root.op)) {
              ext = new ast.Bin_op;
              ext.op = "ASSIGN";
              ext.a = root.a;
              ext.b = root;
              root.op = reg_ret[1];
              return ext;
            } else {
              root.a = walk(root.a, ctx);
              root.b = walk(root.b, ctx);
              return root;
            }
            break;
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.ass_op_unpack = function(root) {
        return walk(root, {
          walk: walk,
          next_gen: module.default_walk
        });
      };
    });
  })(this)();

  check_external_ops = function(scope) {
    var is_external_call, v, _i, _len, _ref, _ref1;
    if (scope.constructor.name === "Scope") {
      _ref = scope.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        v = _ref[_i];
        if (v.constructor.name === "Fn_call" && v.fn.constructor.name === "Field_access") {
          is_external_call = (_ref1 = v.fn.name) === "transfer" || _ref1 === "send" || _ref1 === "call" || _ref1 === "built_in_pure_callback" || _ref1 === "delegatecall";
          if (is_external_call) {
            return true;
          }
        }
        if (v.constructor.name === "Scope") {
          if (check_external_ops(v)) {
            return true;
          }
        }
      }
    }
    return false;
  };

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var contract, f, idx, inject, l, last, ret_types, state_name, t, type, v, _i, _j, _len, _len1, _ref, _ref1;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Ret_multi":
            _ref = root.t_list;
            for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
              v = _ref[idx];
              root.t_list[idx] = walk(v, ctx);
            }
            if (ctx.should_modify_storage) {
              root.t_list.unshift(inject = new ast.Var);
              inject.name = config.contract_storage;
              inject.name_translate = false;
            }
            if (ctx.should_ret_op_list) {
              root.t_list.unshift(inject = new ast.Const);
              inject.type = new Type("built_in_op_list");
              if (ctx.has_op_list_decl) {
                inject.val = config.op_list;
              }
            }
            return root;
          case "If":
            l = root.t.list.last();
            if (l && l.constructor.name === "Ret_multi") {
              l = root.t.list.pop();
              root.t.list.push(inject = new ast.Fn_call);
              inject.fn = new ast.Var;
              inject.fn.name = "@respond";
              inject.arg_list = l.t_list.slice(1);
            }
            f = root.f.list.last();
            if (f && f.constructor.name === "Ret_multi") {
              f = root.f.list.pop();
              root.f.list.push(inject = new ast.Fn_call);
              inject.fn = new ast.Var;
              inject.fn.name = "@respond";
              inject.arg_list = f.t_list.slice(1);
            }
            ctx.has_op_list_decl = true;
            return root;
          case "Fn_decl_multiret":
            ctx.state_mutability = root.state_mutability;
            ctx.should_ret_op_list = root.should_ret_op_list;
            ctx.should_modify_storage = root.should_modify_storage;
            ctx.should_ret_args = root.should_ret_args;
            root.scope = walk(root.scope, ctx);
            ctx.has_op_list_decl = check_external_ops(root.scope);
            state_name = config.storage;
            if (ctx.contract && ctx.contract !== root.contract_name) {
              state_name = "" + state_name + "_" + root.contract_name;
            }
            if (!root.should_ret_args && !root.should_modify_storage) {
              root.arg_name_list.unshift(config.receiver_name);
              root.type_i.nest_list.unshift(contract = new Type("contract"));
              ret_types = [];
              _ref1 = root.type_o.nest_list;
              for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                t = _ref1[_j];
                ret_types.push(translate_type(t, ctx));
              }
              type = ret_types.join(' * ');
              contract.name = config.receiver_name;
              contract.val = type;
              root.type_o.nest_list = [];
              last = root.scope.list.last();
              if (last && last.constructor.name === "Ret_multi") {
                last = root.scope.list.pop();
                root.scope.list.push(inject = new ast.Fn_call);
                inject.fn = new ast.Var;
                inject.fn.name = "@respond";
                inject.arg_list = last.t_list.slice(1);
                ctx.has_op_list_decl = true;
                last = new ast.Ret_multi;
                last = walk(last, ctx);
                root.scope.list.push(last);
              }
            }
            if (ctx.state_mutability !== 'pure') {
              root.arg_name_list.unshift(config.contract_storage);
              root.type_i.nest_list.unshift(new Type(state_name));
            }
            if (ctx.should_modify_storage) {
              root.type_o.nest_list.unshift(new Type(state_name));
            }
            if (ctx.should_ret_op_list) {
              root.type_o.nest_list.unshift(new Type("built_in_op_list"));
            }
            if (root.type_o.nest_list.length === 0) {
              root.type_o.nest_list.unshift(new Type("Unit"));
            }
            last = root.scope.list.last();
            if (!last || last.constructor.name !== "Ret_multi") {
              last = new ast.Ret_multi;
              last = walk(last, ctx);
              root.scope.list.push(last);
            }
            last = root.scope.list.last();
            if (last && last.constructor.name === "Ret_multi" && last.t_list.length !== root.type_o.nest_list.length) {
              last = root.scope.list.pop();
              while (last.t_list.length > root.type_o.nest_list.length) {
                last.t_list.pop();
              }
              while (root.type_o.nest_list.length > last.t_list.length) {
                root.type_o.nest_list.pop();
              }
              root.scope.list.push(last);
            }
            return root;
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.contract_storage_fn_decl_fn_call_ret_inject = function(root, ctx) {
        return walk(root, obj_merge({
          walk: walk,
          next_gen: module.default_walk
        }, ctx));
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var _ref, _ref1;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Class_decl":
            if (root.need_skip) {
              return root;
            }
            if (root.is_library) {
              return root;
            }
            ctx.inheritance_list = root.inheritance_list;
            return ctx.next_gen(root, ctx);
          case "Fn_decl_multiret":
            if (((_ref = root.visibility) !== "private" && _ref !== "internal") && (!ctx.contract || root.contract_name === ctx.contract || ((_ref1 = ctx.inheritance_list) != null ? _ref1[ctx.contract] : void 0))) {
              ctx.router_func_list.push(root);
            }
            return root;
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.router_collector = function(root, opt) {
        var ctx;
        walk(root, ctx = obj_merge({
          walk: walk,
          next_gen: module.default_walk,
          router_func_list: []
        }, opt));
        return ctx.router_func_list;
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var func2args_struct, func2struct, walk;
      func2args_struct = function(name) {
        name = name + "_args";
        name = translate_var_name(name, null);
        return name;
      };
      func2struct = function(name) {
        var new_name;
        name = translate_var_name(name, null);
        name = name.capitalize();
        if (name.length > 31) {
          new_name = name.substr(0, 31);
          perr("WARNING ligo doesn't understand id for enum longer than 31 char so we trim " + name + " to " + new_name + ". Read more: https://github.com/madfish-solutions/sol2ligo/wiki/Known-issues#name-length-for-types");
          name = new_name;
        }
        return name;
      };
      walk = function(root, ctx) {
        var arg, arg_name, call, decl, func, idx, record, ret, value, _case, _enum, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _main, _ref, _ref1, _ref2, _ref3, _ref4, _switch, _var;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Class_decl":
            if (root.is_contract) {
              if (ctx.contract && root.name !== ctx.contract) {
                return ctx.next_gen(root, ctx);
              }
              _ref = ctx.router_func_list;
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                func = _ref[_i];
                root.scope.list.push(record = new ast.Class_decl);
                record.name = func2args_struct(func.name);
                record.namespace_name = false;
                _ref1 = func.arg_name_list;
                for (idx = _j = 0, _len1 = _ref1.length; _j < _len1; idx = ++_j) {
                  value = _ref1[idx];
                  if (func.state_mutability !== "pure") {
                    if (idx < 1) {
                      continue;
                    }
                  }
                  record.scope.list.push(arg = new ast.Var_decl);
                  arg.name = value;
                  arg.type = func.type_i.nest_list[idx];
                }
                if (func.state_mutability === "pure") {
                  record.scope.list.push(arg = new ast.Var_decl);
                  arg.name = config.callback_address;
                  arg.type = new Type("address");
                }
              }
              root.scope.list.push(_enum = new ast.Enum_decl);
              _enum.name = "router_enum";
              _enum.int_type = false;
              _ref2 = ctx.router_func_list;
              for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
                func = _ref2[_k];
                _enum.value_list.push(decl = new ast.Var_decl);
                decl.name = func2struct(func.name);
                decl.type = new Type(func2args_struct(func.name));
              }
              root.scope.list.push(_main = new ast.Fn_decl_multiret);
              _main.name = "@main";
              _main.type_i = new Type("function");
              _main.type_o = new Type("function");
              _main.arg_name_list.push("action");
              _main.type_i.nest_list.push(new Type("router_enum"));
              _main.arg_name_list.push(config.contract_storage);
              _main.type_i.nest_list.push(new Type(config.storage));
              _main.type_o.nest_list.push(new Type("built_in_op_list"));
              _main.type_o.nest_list.push(new Type(config.storage));
              _main.scope.need_nest = false;
              _main.scope.list.push(ret = new ast.Tuple);
              ret.list.push(_switch = new ast.PM_switch);
              _switch.cond = new ast.Var;
              _switch.cond.name = "action";
              _switch.cond.type = new Type("string");
              _ref3 = ctx.router_func_list;
              for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
                func = _ref3[_l];
                _switch.scope.list.push(_case = new ast.PM_case);
                _case.struct_name = func2struct(func.name);
                _case.var_decl.name = "match_action";
                _case.var_decl.type = new Type(_case.struct_name);
                call = new ast.Fn_call;
                call.fn = new ast.Var;
                call.fn.left_unpack = true;
                call.fn.name = func.name;
                if (func.state_mutability === 'pure') {
                  call.fn.type = new Type("function2_pure");
                  call.type = func.type_o.nest_list[0];
                } else {
                  call.fn.type = new Type("function2");
                }
                call.fn.type.nest_list[0] = func.type_i;
                call.fn.type.nest_list[1] = func.type_o;
                _ref4 = func.arg_name_list;
                for (idx = _m = 0, _len4 = _ref4.length; _m < _len4; idx = ++_m) {
                  arg_name = _ref4[idx];
                  if (func.state_mutability !== "pure") {
                    if (idx < 1) {
                      continue;
                    }
                  }
                  call.arg_list.push(arg = new ast.Field_access);
                  arg.t = new ast.Var;
                  arg.t.name = _case.var_decl.name;
                  arg.t.type = _case.var_decl.type;
                  arg.name = arg_name;
                }
                if (!func.should_ret_op_list && func.should_modify_storage) {
                  _case.scope.need_nest = false;
                  _case.scope.list.push(ret = new ast.Tuple);
                  ret.list.push(_var = new ast.Const);
                  _var.type = new Type("built_in_op_list");
                  ret.list.push(call);
                } else if (!func.should_modify_storage) {
                  _case.scope.need_nest = false;
                  _case.scope.list.push(ret = new ast.Tuple);
                  ret.list.push(call);
                  ret.list.push(_var = new ast.Var);
                  _var.type = new Type(config.storage);
                  _var.name = config.contract_storage;
                  _var.name_translate = false;
                } else {
                  _case.scope.need_nest = false;
                  _case.scope.list.push(call);
                }
              }
              return root;
            } else {
              return ctx.next_gen(root, ctx);
            }
            break;
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.add_router = function(root, ctx) {
        return walk(root, obj_merge({
          walk: walk,
          next_gen: module.default_walk
        }, ctx));
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var last, ret;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Comment":
            if (root.text !== "COMPILER MSG PlaceholderStatement") {
              return root;
            }
            ret = ctx.target_ast.clone();
            if (!ctx.need_nest) {
              last = ret.list.last();
              if (last && last.constructor.name === "Ret_multi") {
                last = ret.list.pop();
              }
            }
            return ret;
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.placeholder_replace = function(root, target_ast) {
        return walk(root, {
          walk: walk,
          next_gen: module.default_walk,
          target_ast: target_ast
        });
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Var":
            if (root.name !== ctx.var_name) {
              return root;
            }
            return ctx.target_ast.clone();
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.var_replace = function(root, var_name, target_ast) {
        return walk(root, {
          walk: walk,
          next_gen: module.default_walk,
          var_name: var_name,
          target_ast: target_ast
        });
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var class_decl, fn_call, found_constructor, i, inheritance_apply_list, inheritance_list, is_constructor_name, look_list, need_constuctor, need_lookup_list, parent, v, _i, _j, _k, _l, _len, _len1, _len2, _len3, _m, _ref, _ref1;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Class_decl":
            is_constructor_name = function(name) {
              return name === "constructor" || name === root.name;
            };
            root = ctx.next_gen(root, ctx);
            ctx.class_hash[root.name] = root;
            if (!root.inheritance_list.length) {
              return root;
            }
            inheritance_apply_list = [];
            inheritance_list = root.inheritance_list;
            while (inheritance_list.length) {
              need_lookup_list = [];
              for (i = _i = _ref = inheritance_list.length - 1; _i >= 0; i = _i += -1) {
                v = inheritance_list[i];
                if (!ctx.class_hash.hasOwnProperty(v.name)) {
                  throw new Error("can't find parent class " + v.name);
                }
                class_decl = ctx.class_hash[v.name];
                class_decl.need_skip = true;
                inheritance_apply_list.push(v);
                need_lookup_list.append(class_decl.inheritance_list);
              }
              inheritance_list = need_lookup_list;
            }
            root = root.clone();
            for (_j = 0, _len = inheritance_apply_list.length; _j < _len; _j++) {
              parent = inheritance_apply_list[_j];
              if (!ctx.class_hash.hasOwnProperty(parent.name)) {
                throw new Error("can't find parent class " + parent.name);
              }
              class_decl = ctx.class_hash[parent.name];
              if (class_decl.is_interface) {
                continue;
              }
              look_list = class_decl.scope.list;
              need_constuctor = null;
              for (_k = 0, _len1 = look_list.length; _k < _len1; _k++) {
                v = look_list[_k];
                if (v.constructor.name !== "Fn_decl_multiret") {
                  continue;
                }
                v = v.clone();
                if (is_constructor_name(v.name)) {
                  v.name = "" + parent.name + "_constructor";
                  v.visibility = "internal";
                  need_constuctor = v;
                }
                root.scope.list.unshift(v);
              }
              for (_l = 0, _len2 = look_list.length; _l < _len2; _l++) {
                v = look_list[_l];
                if (v.constructor.name !== "Var_decl") {
                  continue;
                }
                root.scope.list.unshift(v.clone());
              }
              if (!need_constuctor) {
                continue;
              }
              found_constructor = null;
              _ref1 = root.scope.list;
              for (_m = 0, _len3 = _ref1.length; _m < _len3; _m++) {
                v = _ref1[_m];
                if (v.constructor.name !== "Fn_decl_multiret") {
                  continue;
                }
                if (!is_constructor_name(v.name)) {
                  continue;
                }
                found_constructor = v;
                break;
              }
              if (!found_constructor) {
                root.scope.list.unshift(found_constructor = new ast.Fn_decl_multiret);
                found_constructor.name = "constructor";
                found_constructor.type_i = new Type("function");
                found_constructor.type_o = new Type("function");
              }
              found_constructor.scope.list.unshift(fn_call = new ast.Fn_call);
              fn_call.fn = new ast.Var;
              fn_call.fn.name = need_constuctor.name;
            }
            return root;
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.inheritance_unpack = function(root) {
        return walk(root, {
          walk: walk,
          next_gen: module.default_walk,
          class_hash: {}
        });
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var walk;
      walk = function(root, ctx) {
        var add, addmod, mul, mulmod;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Fn_call":
            if (root.fn.constructor.name === "Var") {
              switch (root.fn.name) {
                case "addmod":
                  add = new ast.Bin_op;
                  add.op = "ADD";
                  add.a = root.arg_list[0];
                  add.b = root.arg_list[1];
                  addmod = new ast.Bin_op;
                  addmod.op = "MOD";
                  addmod.b = root.arg_list[2];
                  addmod.a = add;
                  perr("WARNING `addmod` translation may compute incorrectly due to possible overflow. Read more: https://github.com/madfish-solutions/sol2ligo/wiki/Known-issues#number-types");
                  return addmod;
                case "mulmod":
                  mul = new ast.Bin_op;
                  mul.op = "MUL";
                  mul.a = root.arg_list[0];
                  mul.b = root.arg_list[1];
                  mulmod = new ast.Bin_op;
                  mulmod.op = "MOD";
                  mulmod.b = root.arg_list[2];
                  mulmod.a = mul;
                  perr("WARNING `mulmod` translation may compute incorrectly due to possible overflow. Read more: https://github.com/madfish-solutions/sol2ligo/wiki/Known-issues#number-types");
                  return mulmod;
              }
            }
            return root;
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.math_funcs_convert = function(root, ctx) {
        return walk(root, obj_merge({
          walk: walk,
          next_gen: module.default_walk
        }, ctx));
      };
    });
  })(this)();

  (function(_this) {
    return (function() {
      var fn_apply_modifier, walk;
      fn_apply_modifier = function(fn, mod, ctx) {

        /*
        Possible intersections
          1. Var_decl
          2. Var_decl in arg_list
          3. Multiple placeholders = multiple cloned Var_decl
         */
        var arg, idx, mod_decl, prepend_list, ret, var_decl, _i, _len, _ref;
        if (mod.fn.constructor.name !== "Var") {
          throw new Error("unimplemented");
        }
        if (!ctx.modifier_hash.hasOwnProperty(mod.fn.name)) {
          throw new Error("unknown modifier " + mod.fn.name);
        }
        mod_decl = ctx.modifier_hash[mod.fn.name];
        ret = mod_decl.scope.clone();
        prepend_list = [];
        _ref = mod.arg_list;
        for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
          arg = _ref[idx];
          if (arg.name === mod_decl.arg_name_list[idx]) {
            continue;
          }
          prepend_list.push(var_decl = new ast.Var_decl);
          var_decl.name = mod_decl.arg_name_list[idx];
          var_decl.assign_value = arg.clone();
          var_decl.type = mod_decl.type_i.nest_list[idx];
        }
        ret = module.placeholder_replace(ret, fn);
        ret.list = arr_merge(prepend_list, ret.list);
        return ret;
      };
      walk = function(root, ctx) {
        var idx, inner, mod, ret, _i, _len, _ref;
        walk = ctx.walk;
        switch (root.constructor.name) {
          case "Fn_decl_multiret":
            if (root.is_modifier) {
              ctx.modifier_hash[root.name] = root;
              ret = new ast.Comment;
              ret.text = "modifier " + root.name + " inlined";
              return ret;
            } else {
              if (root.is_constructor) {
                ctx.modifier_hash[root.contract_name] = root;
              }
              if (root.modifier_list.length === 0) {
                return root;
              }
              inner = root.scope.clone();
              _ref = root.modifier_list;
              for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
                mod = _ref[idx];
                inner.need_nest = false;
                inner = fn_apply_modifier(inner, mod, ctx);
              }
              inner.need_nest = true;
              ret = root.clone();
              ret.modifier_list.clear();
              ret.scope = inner;
              return ret;
            }
            break;
          default:
            return ctx.next_gen(root, ctx);
        }
      };
      return _this.modifier_unpack = function(root) {
        return walk(root, {
          walk: walk,
          next_gen: module.default_walk,
          modifier_hash: {}
        });
      };
    });
  })(this)();

  this.ligo_pack = function(root, opt) {
    var router_func_list;
    if (opt == null) {
      opt = {};
    }
    if (opt.router == null) {
      opt.router = true;
    }
    root = module.var_translate(root);
    root = module.require_distinguish(root);
    root = module.fix_missing_emit(root);
    root = module.fix_modifier_order(root);
    root = module.for3_unpack(root);
    root = module.math_funcs_convert(root);
    root = module.ass_op_unpack(root);
    root = module.modifier_unpack(root);
    root = module.inheritance_unpack(root);
    root = module.contract_storage_fn_decl_fn_call_ret_inject(root, opt);
    if (opt.router) {
      router_func_list = module.router_collector(root, opt);
      root = module.add_router(root, obj_merge({
        router_func_list: router_func_list
      }, opt));
    }
    return root;
  };

}).call(window.ast_transform = {});
