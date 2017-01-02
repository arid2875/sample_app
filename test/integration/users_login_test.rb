require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  
  def setup
    @user = users(:michael)
  end

  test "only show activated users on index" do
    log_in_as(@user)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination'
    User.paginate(page: 1).each do |user|
      if user.activated?
        assert_select 'a[href=?]', user_path(user), text: user.name
        if user == @admin
          assert_select 'a[href=?]', user_path(user), text: 'delete'
        end
      else
        assert_select 'a[href=?]', user_path(user), text: user.name, count: 0
      end      
    end
  end

  test "login with invalid information" do
    get login_path
    assert_template 'sessions/new'
    post login_path, params: { session: { email: "", password: "" } }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?    
  end

  test "login with valid information followed by logout" do
    get login_path
    post login_path, params: { session: { email:    @user.email,
                                          password: 'password' } }
    assert is_logged_in?
    unless @user.activated?
      assert_redirected_to root_url
    else
      assert_redirected_to @user
      follow_redirect!            
      assert_template 'users/show'
      assert_select "a[href=?]", login_path, count: 0
      assert_select "a[href=?]", logout_path
      assert_select "a[href=?]", user_path(@user)
      delete logout_path
      assert_not is_logged_in?
      assert_redirected_to root_url
      delete logout_path
      follow_redirect!
      assert_select "a[href=?]", login_path
      assert_select "a[href=?]", logout_path,      count: 0
      assert_select "a[href=?]", user_path(@user), count: 0
    end

  end

  test "login with remembering" do
    log_in_as(@user, remember_me: '1')
    assert_equal cookies['remember_token'], assigns(:user).remember_token
  end

  test "login without remembering" do
    log_in_as(@user, remember_me: '1')
    log_in_as(@user, remember_me: '0')
    assert_empty cookies['remember_token']
  end   
end
