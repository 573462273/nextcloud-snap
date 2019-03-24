feature "Change ports" do
	scenario "http" do
		`sudo snap set nextcloud ports.http=81`
		expect($?.to_i).to eq 0
		wait_for_nextcloud(port: 81)
		Capybara.app_host = 'http://localhost:81'

		assert_login
		assert_uri(https: false, port: 81)

		# Also assert that we can change it back to the default
		`sudo snap set nextcloud ports.http=80`
		expect($?.to_i).to eq 0
		wait_for_nextcloud
		Capybara.app_host = 'http://localhost'

		assert_logged_in
		assert_uri(https: false, port: 80)
	end

	scenario "https" do
		enable_https

		`sudo snap set nextcloud ports.https=444`
		expect($?.to_i).to eq 0
		wait_for_nextcloud(https: true, port: 444)
		Capybara.app_host = 'https://localhost:444'

		assert_login
		assert_uri(https: true, port: 444)

		# Also assert that we can change it back to the default
		`sudo snap set nextcloud ports.https=443`
		expect($?.to_i).to eq 0
		wait_for_nextcloud(https: true)
		Capybara.app_host = 'https://localhost'

		assert_logged_in
		assert_uri(https: true, port: 443)
	end


	scenario "http still redirects to unchanged https" do
		enable_https

		`sudo snap set nextcloud ports.http=81`
		expect($?.to_i).to eq 0
		wait_for_nextcloud(port: 81)
		Capybara.app_host = 'http://localhost:81'

		assert_login
		assert_uri(https: true, port: 443)
	end


	scenario "http redirects to changed https" do
		enable_https

		`sudo snap set nextcloud ports.http=81 ports.https=444`
		expect($?.to_i).to eq 0
		wait_for_nextcloud(port: 81)
		Capybara.app_host = 'http://localhost:81'

		assert_login
		assert_uri(https: true, port: 444)
	end

	scenario "Let's Encrypt challenge request" do
		enable_https

		# Assert we do not redirect under the four possibilities for
		# changing or not changing ports
		assert_lets_encrypt_challenge(http_port: 80, https_port: 443)
		assert_lets_encrypt_challenge(http_port: 80, https_port: 444)
		assert_lets_encrypt_challenge(http_port: 81, https_port: 443)
		assert_lets_encrypt_challenge(http_port: 81, https_port: 444)
	end

	protected

	def assert_uri(https:, port:)
		uri = URI.parse(current_url)
		if https
			expect(uri.scheme).to eq 'https'
		else
			expect(uri.scheme).to eq 'http'
		end

		expect(uri.host).to eq 'localhost'
		expect(uri.port).to eq port
	end

	def assert_login
		visit "/"
		fill_in "User", with: "admin"
		fill_in "Password", with: "admin"
		click_button "Log in"
		expect(page).to have_content "Documents"
	end

	def assert_logged_in
		visit "/"
		expect(page).to have_content "Documents"
	end

	def assert_lets_encrypt_challenge(http_port:, https_port:)
		`sudo snap set nextcloud ports.http=#{http_port} ports.https=#{https_port}`
		expect($?.to_i).to eq 0
		wait_for_nextcloud(https: false, port: http_port)
		Capybara.app_host = "http://localhost:#{http_port}"

		visit "/.well-known/acme-challenge/a-challenge-path"
		assert_uri(https: false, port: http_port)
	end
end
