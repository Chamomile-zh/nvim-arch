local running_commands = {}

local commands = {
  ['c'] = {
    command = {
      'gcc "$filename" -o "$runfile"',
      './"$runfile"',
      'rm -f "$runfile"',
    },
  },
  ['cpp'] = {
    command = {
      'g++ "$filename" -std=c++20 -O2 -g -Wall -o "$runfile"',
      './"$runfile"',
      'rm -rf "$runfile"',
    },
  },
  ['make'] = {
    command = {
      'cd $workspace',
      'make test',
    },
    modus = 'center',
  },
  ['c_lib'] = {
    command = 'gcc -c -fPIC -shared "$filename" -o lib"$runfile".so',
    modus = 'job',
  },
  ['cpp_lib'] = {
    command = 'g++ -c -fPIC -shared "$filename" -o lib"$runfile".so',
    modus = 'job',
  },
  ['c_build'] = {
    command = 'gcc "$filename" -o "$runfile"',
    -- 不写 modus，默认弹窗。这样如果代码有语法错误，你能第一时间在小窗里看到 gcc 的报错。
  },

  ['cpp_build'] = {
    command = 'g++ "$filename" -std=c++20 -O2 -g -Wall -o "$runfile"',
  },

  ['go'] = {
    command = 'go run "$filename"',
  },
  ['python'] = {
    command = 'python3 "$filename"',
  },
  ['lua'] = {
    command = 'luajit "$filename"',
  },
  ['sh'] = {
    command = 'bash "$filename"',
  },
  ['html'] = {
    command = 'live-server --browser=' .. vim.g.browser,
    modus = 'job',
  },
  ['markdown'] = {
    command = 'typora "$filename"',
    modus = 'job',
  },
  ['rust'] = {
    command =
      -- {
      --   'rustc "$filename" -o "$runfile"',
      --   './"$runfile"',
      --   'rm -rf "$runfile"',
      -- },
      'cargo run',
  },

  ['rust_build'] = {
    command = 'cargo build --release',
  },
  ['typescript'] = {
    command = 'deno run "$filename"',
  },
}

function running_commands.get_commands()
  return commands
end

function running_commands.commands_list()
  return vim.tbl_keys(commands)
end

return running_commands
