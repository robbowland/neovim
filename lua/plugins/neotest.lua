return {
  "nvim-neotest/neotest",
  -- Workaround for 'tests not found' with neotest-jest due to broken neotest
  -- Issue: https://github.com/nvim-neotest/neotest/issues/531
  commit = "52fca6717ef972113ddd6ca223e30ad0abb2800c",
  opts = { adapters = { "neotest-jest" } },
  dependencies = { "haydenmeade/neotest-jest" },
}
