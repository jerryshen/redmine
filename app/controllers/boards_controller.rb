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

class BoardsController < ApplicationController
  default_search_scope :messages
  before_filter :find_project_by_project_id, :find_board_if_available, :authorize
  accept_rss_auth :index, :show

  helper :sort
  include SortHelper
  helper :watchers

  def index
    @boards = @project.boards
    # show the board if there is only one
    if @boards.size == 1
      @board = @boards.first
      show
    end
  end

  def show
    respond_to do |format|
      format.html {
        sort_init 'updated_on', 'desc'
        sort_update	'created_on' => "#{Message.table_name}.created_on",
                    'replies' => "#{Message.table_name}.replies_count",
                    'updated_on' => "#{Message.table_name}.updated_on"

        @topic_count = @board.topics.count
        @topic_pages = Paginator.new self, @topic_count, per_page_option, params['page']
        @topics =  @board.topics.find :all, :order => ["#{Message.table_name}.sticky DESC", sort_clause].compact.join(', '),
                                      :include => [:author, {:last_reply => :author}],
                                      :limit  =>  @topic_pages.items_per_page,
                                      :offset =>  @topic_pages.current.offset
        @message = Message.new
        render :action => 'show', :layout => !request.xhr?
      }
      format.atom {
        @messages = @board.messages.find :all, :order => 'created_on DESC',
                                               :include => [:author, :board],
                                               :limit => Setting.feeds_limit.to_i
        render_feed(@messages, :title => "#{@project}: #{@board}")
      }
    end
  end

  def new
    @board = @project.boards.build(params[:board])
  end

  verify :method => :post, :only => :create, :redirect_to => { :action => :index }
  def create
    @board = @project.boards.build(params[:board])
    if @board.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_settings_in_projects
    else
      render :action => 'new'
    end
  end

  def edit
  end

  verify :method => :put, :only => :update, :redirect_to => { :action => :index }
  def update
    if @board.update_attributes(params[:board])
      redirect_to_settings_in_projects
    else
      render :action => 'edit'
    end
  end

  verify :method => :delete, :only => :destroy, :redirect_to => { :action => :index }
  def destroy
    @board.destroy
    redirect_to_settings_in_projects
  end

private
  def redirect_to_settings_in_projects
    redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'boards'
  end

  def find_board_if_available
    @board = @project.boards.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end