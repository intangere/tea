import tea
import json

const (
	port = 8080
)

struct App {
        tea.Context
pub mut:
        validators tea.Validators<App>
}

// custom structs for data modeling
struct User{
        username string
        password string
}

struct UserParams{
	user_id string
}

struct Params {
pub mut:
	username string
	page string
}

// functions for data validation
fn (user User) is_valid() bool {
	username := user.username.strip_margin()
	password := user.password.strip_margin()
	return username.len > 3 &&
		password.len > 8
}

fn (user UserParams) is_valid() bool {
	return user.user_id.strip_margin().len > 0 &&
		user.user_id.int() > 0
}

fn (params Params) is_valid() bool {
	return params.username.len > 3 && params.page.int() >= 0
}

// route functions
['/']
// normal route. no validation 
fn (mut app App) index() tea.Result {
	return app.json(json.encode(tea.Response{status: 'Welcome!'}))
}

['/login'; post]
// validated post route
fn (mut app App) login(user User) tea.Result {
        println('Logging in user: ' + user.username + ' with password: ' + user.password)
	return app.json(json.encode(tea.Response{status: 'success'}))
}

['/user/:user_id']
//normal vweb url parameter
fn (mut app App) user(id string) tea.Result {
	return app.json('{"user_id":"$id"}')
}

['/some/:some_id']
// validated url parameter
fn (mut app App) some_id(id int) tea.Result {
	return app.json('{"id":$id}')
}

['/params']
// get route with parameter validation
fn (mut app App) params(params Params) tea.Result {
	println('Got params: ' + params.str())
	return app.json(json.encode(tea.Response{status: 'valid parameters'}))
}

['/params_raw']
// get route with parameter validation without passing params
fn (mut app App) params_raw() tea.Result {
	println('Raw params: ' + app.query.str())
	return app.json(json.encode(tea.Response{status: 'valid parameters'}))
}

['/check_header']
// get route with header validation without passing params
fn (mut app App) check_header(token string) tea.Result {
	println('Token: ' + token)
	return app.json(json.encode(tea.Response{status: 'received token'}))
}

['/settings/:user_id']
// validate literally everything to see if its possible [broken]
fn (mut app App) settings(params Params, user User, user_id string) tea.Result {
	return app.json(json.encode(tea.Response{status: 'working'}))
}

fn (mut app App) validation_error(reason string) tea.Result {
	return app.json(json.encode(tea.Response{status: 'validation failed: $reason'}))
}

fn main(){
	println('vweb with data modeling and validation')

	mut app := App{}	

	login_validator := fn (mut app App) { 
		model := tea.decode_model<User>(app.req.data)
		if !model.is_valid() {
			app.validation_error('username or password too short')
			return
		}
		app.login(model)
	}

	params_validator := fn (mut app App) {
		model := tea.from_map<Params>(app.query)
		if !model.is_valid() {
			app.validation_error('One or more parameters are invalid')
			return
		}
		app.params(model)
	}

	params_validator_raw := fn (mut app App) {
		model := tea.from_map<Params>(app.query)
		if !model.is_valid() {
			app.validation_error('One or more parameters are invalid')
			return
		}
		app.params_raw()
	}

	some_id_validator := fn (mut app App) {
		id := app.url_params['some_id'] or { '0' }
		println(id)
		if id.int() <= 0 {
			app.validation_error('id value is too low')
			return
		}
		app.some_id(id.int())
	}

	header_validator := fn (mut app App) {
		token := app.req.header.get(.authorization) or { '' }
		if token.len != 32 || token == '' {
			app.validation_error('Invalid token length')
			return
		}
		app.check_header(token)

	}

	validate_everything := fn (mut app App) {
		id := app.url_params['user_id']
		query_model := tea.from_map<Params>(app.query)
		user_model := tea.decode_model<User>(app.req.data)

		if id.int() <= 0 || !query_model.is_valid() || !user_model.is_valid() {
			app.validation_error('One or more parameters are invalid')
			return
		}
		
		app.settings(query_model, user_model, id)
	}

	app.validators.validators['/login'] = login_validator
	app.validators.validators['/params'] = params_validator
	app.validators.validators['/params_raw'] = params_validator_raw
	app.validators.validators['/check_header'] = header_validator
	app.validators.validators['/some/:some_id'] = some_id_validator
	app.validators.validators['/settings/:user_id'] = validate_everything

	tea.run(&app, port)
}

