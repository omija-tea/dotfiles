local wezterm = require 'wezterm'
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- 공통 설정 로드
local common = require 'config.common'
for k, v in pairs(common) do
  config[k] = v
end

-- OS별 설정 병합
local target = wezterm.target_triple
local platform_config

if target:find 'darwin' then
  platform_config = require 'config.macos'
elseif target:find 'windows' then
  platform_config = require 'config.windows'
end

if platform_config then
  for k, v in pairs(platform_config) do
    config[k] = v
  end
end

return config