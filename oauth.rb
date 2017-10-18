


EXPLAINING Oauth
<p>Log in to resume your learning</p>
<a href= "https://github.com/login/oauth/authorize?scope=user:email&client_id=74fe2b9c76d0ac9fbcce" type="button" name="button">Log in with Github</a>
#click here goes to github once it comes back we specify the url with the client id (my callback url is defind in our app github)
	<br>
	<br>

#github will authorize and send it back to callback because that is the route we need to take the github information and integrate it
def callback
session_code = request.env['rack.request.query_hash']['code']
# we take the code that github returns and sends it back to github (as per and POST comment )
	client_id_key = ENV["CLIENT_ID"]
	client_secret_key = ENV["CLIENT_SECRET"]


	# ... and POST it back to GitHub with client and secret ID
	result = RestClient.post('https://github.com/login/oauth/access_token',{:client_id => client_id_key,:client_secret => client_secret_key,:code => session_code},:accept => :json)

	#  extract the token and granted scopes (JSON token stored as a session)
	session[:access_token] = JSON.parse(result)['access_token']
	redirect_to '/oauth' #redirect to oauth route / use oauth method
 end


def oauth
		access_token = session[:access_token]
		# 1. saves our session token as a variable which is critical to getting a session to persist (i.e remain logged in)
		auth_result = RestClient.get('https://api.github.com/user',{:params => {:access_token => access_token},:accept => :json})
		# 2. Quite clear auth_result asks the github api to give us the users information 2nd part confirms JSON must be the format.

		auth_result = JSON.parse(auth_result)
		#3 parse the auth_result as a JSON file (ie read it as JSON and then save it as the new auth_result)
		auth_result['private_emails'] = JSON.parse(RestClient.get('https://api.github.com/user/emails',{:params => {:access_token => access_token},:accept => :json}))
		#4 some people on github dont make their email public but we still have that access -> since that email is not shared with other users
		@user = User.find_by_email(auth_result['private_emails'][0]['email'])
		#5 Allows us to find user by first email that would come up -> therefore not causing any confusion about the one we are referring to
		if !@user.present?
			@user= User.create(name: auth_result["name"], email: auth_result['private_emails'][0]['email'] ,password:'Oauth',password_confirmation: 'Oauth' )
		end
# 6  if the user email exists in our database we do nothing exept authorize the user and set a session so they can use the service and it will not conflict (allowing them to login essentially)
	# iF NOT IN THE DATABASE WE CREATE IT
		puts @user
		session[:user_id] = @user.id
	redirect_to menu_index_path,
# redirect to the page we want them to go to (this is an easy one for all of us)
