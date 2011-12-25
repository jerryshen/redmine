# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)
require 'settings_controller'

# Re-raise errors caught by the controller.
class SettingsController; def rescue_action(e) raise e end; end

class SettingsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @controller = SettingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'edit'
  end

  def test_get_edit
    get :edit
    assert_response :success
    assert_template 'edit'
  end

  def test_post_edit_notifications
    post :edit, :settings => {:mail_from => 'functional@test.foo',
                              :bcc_recipients  => '0',
                              :notified_events => %w(issue_added issue_updated news_added),
                              :emails_footer => 'Test footer'
                              }
    assert_redirected_to '/settings/edit'
    assert_equal 'functional@test.foo', Setting.mail_from
    assert !Setting.bcc_recipients?
    assert_equal %w(issue_added issue_updated news_added), Setting.notified_events
    assert_equal 'Test footer', Setting.emails_footer
  end

  def test_get_plugin_settings
    Setting.stubs(:plugin_foo).returns({'sample_setting' => 'Plugin setting value'})
    ActionController::Base.view_paths.unshift(File.join(Rails.root, "test/fixtures/plugins"))
    Redmine::Plugin.register :foo do
      settings :partial => "foo_plugin/foo_plugin_settings"
    end

    get :plugin, :id => 'foo'
    assert_response :success
    assert_template 'plugin'
    assert_tag 'form', :attributes => {:action => '/settings/plugin/foo'},
      :descendant => {:tag => 'input', :attributes => {:name => 'settings[sample_setting]', :value => 'Plugin setting value'}}

    Redmine::Plugin.clear
  end

  def test_get_invalid_plugin_settings
    get :plugin, :id => 'none'
    assert_response 404
  end

  def test_post_plugin_settings
    Setting.expects(:plugin_foo=).with({'sample_setting' => 'Value'}).returns(true)
    Redmine::Plugin.register(:foo) {}

    post :plugin, :id => 'foo', :settings => {'sample_setting' => 'Value'}
    assert_redirected_to '/settings/plugin/foo'
  end
end