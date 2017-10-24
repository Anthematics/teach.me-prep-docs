require 'httparty'

class UsersController < ApplicationController
	protect_from_forgery except: :submitcode


	def new
	end

	def create
		@user.email = params[:user][:email]
		@user.password = params[:user][:password]
		@user.password_confirmation = params[:user][:password_confirmation]

		if @user.save
			session[:user_id] = @user.id

			redirect_to menu_index_path
		else
			render :new
		end
	end

	def submitcode
		 @usercode = params[:code]
		 @step = Step.find(params[:step_id]) #finds which step you are on so it knows which tests to run
		 @total_test = @step.code_tests.count #can test multiple times if code works this way
		 @valid = 0
		 @step.code_tests.each do |test| #iterate thru each test that exists for that step
		 @testcode = @usercode + "\n print " + test.input # requires an explicit result to print in this case so we can compare with output.
			 response = HTTParty.post("https://codeapi.herokuapp.com/code/ruby",:body => {:step => {:code => @testcode}}) #ajax call to mini app for eval
			 puts response.body
				body = JSON.parse(response.body) #info will come back as JSON please parse
				puts body.to_s #btw needs to be a string
				puts test.output # please put the output explicit so we can compare the requred output with outs
				if body.to_s == test.output # now compare the 2 and if they = each other
					@valid += 1 #another test is valid
				end
			end

		if @total_test == @valid # if we pass all tests
			if UserStep.find_by(user_id: current_user.id, step_id: @step.id).present? #in the user test table , if this person already wrote this test and they're making adjustments we are giving the ability for the database -> because when updated we dont want to make the file bigger
				@user_steps = UserStep.first.update_attributes(userCode: @usercode)
			else
			@user_steps = UserStep.create!(user_id: current_user.id, step_id: params[:step_id], userCode: @usercode) #creates a new space in the DB with new code assuming it hasn't been written yet.
			end

			url =  "/languages/" + @step.chapter.language.name + "/chapters/" + @step.chapter.id.to_s + "/steps/" + (@step.id + 1).to_s
			render json: {message: "Congratulations, you pass this Step!", pass: true, url: url}
		else
			render json: {message: "Try again!, you passed #{@valid} test out of #{@total_test}.", pass:false}
		end
	end

	def show
	end

	def current_language
		@current_language = Language.find_by! name: params[:language_language_id]
	end

end
