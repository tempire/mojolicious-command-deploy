# Usage
deploy heroku [OPTIONS]

  # Create new app with randomly selected name and deploy
  $0 deploy heroku -c

  # Create new app with specified name and deploy
  $0 deploy heroku -c -n happy-cloud-1234

  # Deploy to existing app
  $0 deploy heroku -n happy-cloud-1234

These options are available:
  -n, --appname <name>      Specify app for deployment
  -a, --api-key <api_key>   Heroku API key (read from ~/.heroku/credentials by default).
  -c, --create              Create a new Heroku app
  -v, --verbose             Verbose output (heroku response, git output)
  -h, --help                This message

# Example
`
mojo generate app MyApp
cd my_app
script/my_app generate makefile
script/my_app generate heroku
script/my_app deploy heroku
`

