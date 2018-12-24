# frozen_string_literal: true

require 'spec_helper'
require 'selenium-webdriver'
require 'shared_selenium_session'
require 'rspec/shared_spec_matchers'

Capybara.register_driver :selenium_ie do |app|
  # ::Selenium::WebDriver.logger.level = "debug"
  options = ::Selenium::WebDriver::IE::Options.new
  options.require_window_focus = true
  Capybara::Selenium::Driver.new(
    app,
    browser: :ie,
    desired_capabilities: ::Selenium::WebDriver::Remote::Capabilities.ie,
    options: options
  )
end

if ENV['REMOTE']
  Capybara.register_driver :selenium_ie do |app|
    url = 'http://192.168.56.101:4444/wd/hub'
    browser_options = ::Selenium::WebDriver::IE::Options.new
    # browser_options.require_window_focus = true

    Capybara::Selenium::Driver.new app,
                                   browser: :remote,
                                   desired_capabilities: :ie,
                                   options: browser_options,
                                   url: url
  end

  Capybara.server_host = '10.24.4.135'
end

module TestSessions
  SeleniumIE = Capybara::Session.new(:selenium_ie, TestApp)
end

TestSessions::SeleniumIE.driver.browser.file_detector = lambda do |args|
  str = args.first.to_s
  str if File.exist?(str)
end if ENV['REMOTE']

TestSessions::SeleniumIE.current_window.resize_to(800, 500)

skipped_tests = %i[response_headers status_code trigger modals hover form_attribute windows]

$stdout.puts `#{Selenium::WebDriver::IE.driver_path} --version` if ENV['CI']

TestSessions::SeleniumIE.current_window.resize_to(1600, 1200)

Capybara::SpecHelper.run_specs TestSessions::SeleniumIE, 'selenium', capybara_skip: skipped_tests do |example|
  case example.metadata[:full_description]
  when /#refresh it reposts$/
    skip 'IE insists on prompting without providing a way to suppress'
  when /#click_link can download a file$/
    skip 'Not sure how to configure IE for automatic downloading'
  when /#fill_in with Date /
    pending "IE 11 doesn't support date input types"
  when /#click_link_or_button with :disabled option happily clicks on links which incorrectly have the disabled attribute$/
    skip 'IE 11 obeys non-standard disabled attribute on anchor tag'
  when /#right_click should allow modifiers$/
    skip "Windows can't :meta click because :meta triggers start menu"
  when /#click should allow modifiers$/
    pending "Doesn't work with IE for some unknown reason$"
  when /#double_click should allow modifiers$/
    pending "Doesn't work with IE for some unknown reason$"
  when /#click should allow multiple modifiers$/
    skip "Windows can't :meta click because :meta triggers start menu"
  when /#double_click should allow multiple modifiers$/
    skip "Windows can't :alt double click due to being properties shortcut"
  when /#has_css\? should support case insensitive :class and :id options$/
    pending "IE doesn't support case insensitive CSS selectors"
  when /#reset_session! removes ALL cookies$/
    pending "IE driver doesn't provide a way to remove ALL cookies"
  when /#click_button should send button in document order$/
    pending "IE 11 doesn't support the 'form' attribute"
  when /#click_button should follow permanent redirects that maintain method$/
    pending "Window 7 and 8.1 don't support 308 http status code"
  when /#scroll_to can scroll an element to the center of the viewport$/,
       /#scroll_to can scroll an element to the center of the scrolling element$/
    pending " IE doesn't support ScrollToOptions"
  end
end

RSpec.describe 'Capybara::Session with Internet Explorer', capybara_skip: skipped_tests do # rubocop:disable RSpec/MultipleDescribes
  include Capybara::SpecHelper
  include_examples 'Capybara::Session', TestSessions::SeleniumIE, :selenium_ie
  include_examples Capybara::RSpecMatchers, TestSessions::SeleniumIE, :selenium_ie
end

RSpec.describe Capybara::Selenium::Node do
  it '#right_click should allow modifiers' do
    pending "Actions API doesn't appear to work for this"
    session = TestSessions::SeleniumIE
    session.visit('/with_js')
    el = session.find(:css, '#click-test')
    el.right_click(:control)
    expect(session).to have_link('Has been control right clicked')
  end

  it '#click should allow multiple modifiers' do
    pending "Actions API doesn't appear to work for this"
    session = TestSessions::SeleniumIE
    session.visit('with_js')
    # IE triggers system behavior with :meta so can't use those here
    session.find(:css, '#click-test').click(:ctrl, :shift, :alt)
    expect(session).to have_link('Has been alt control shift clicked')
  end

  it '#double_click should allow modifiers' do
    pending "Actions API doesn't appear to work for this"
    session = TestSessions::SeleniumIE
    session.visit('/with_js')
    session.find(:css, '#click-test').double_click(:shift)
    expect(session).to have_link('Has been shift double clicked')
  end
end
