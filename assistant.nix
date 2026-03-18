{lib, ...}: {
  programs.nvf.settings.vim.assistant.avante-nvim = {
    enable = false;
    setupOpts = {
      provider = "ollama";
      auto_suggestions_provider = "ollama";

      behaviour = {
        auto_suggestions = true;
        auto_set_highlight_group = true;
      };

      providers = {
        ollama = {
          endpoint = "http://192.168.55.2:11434/"; # Added /v1
          model = "qwen2.5-coder:0.5b"; # Use the tag name from 'ollama list'
          timeout = 15000;
          # parse_curl_args = ""; # Optional: helper for nix
          # parse_stream_data = ""; # Optional: helper for nix
        };
      };
    };
  };
}
