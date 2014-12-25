module Firebots
  class Teamwork

    class << self

      def new_user(user)
        params = {
          person: {
            :'first-name' => user[:first_name],
            :'last-name' => user[:last_name],
            :'email-address' => user[:email],
            :'user-type' => 'account',
            :'user-name' => user[:username],
            :'company-id' => '21193',
            title: '',
            :'phone-number-mobile' => '',
            :'phone-number-office' => '',
            :'phone-number-office-ext' => '',
            :'phone-number-fax' => '',
            :'phone-number-home' => '',
            :'im-handle' => '',
            :'im-service' => '',
            dateFormat: 'mm/dd/yyyy',
            sendWelcomeEmail: 'yes',
            welcomeEmailMessage: '',
            receiveDailyReports: 'no',
            autoGiveProjectAccess: 'yes',
            openID: '',
            notes: '',
            userLanguage: 'EN',
            administrator: 'no',
            canAddProjects: 'no',
            timezoneId: '3',
          },
        }

        response = send_request('/people.json', params, {status: 'ALL'})

        return {
          success: false,
          error: response,
        } unless response['STATUS'] == 'OK'

        # get the person's id from the header response
        id = res.header_str.split("\r\n").select do |h|
          h.start_with?('id: ')
        end.first.gsub(/\D/, '')

        add_to_projects(id)

        {
          success: true,
          response: response,
        }
      end

      def add_to_projects(id)
        get('/projects.json')['projects'].each do |p|
          Thread.new do
            send_request("/projects/#{p['id']}/people/#{id}.json")
          end
        end
      end


      private

      API_PROTOCOL = :HTTPS
      API_HOST = 'fremonthighroboticsteam.teamwork.com'
      AUTH = lambda do |curl|
        curl.headers['Accept'] = 'application/json'
        curl.headers['Content-Type'] = 'application/json'

        curl.http_auth_types = :basic
        curl.username = Konfiguration.creds(:teamwork, :username)
        curl.password = 'none'
      end

      def api_url(endpoint, params={})
        URI.const_get(API_PROTOCOL).build(
          host: API_HOST,
          path: endpoint,
          query: params.empty? ? nil : URI.encode_www_form(params),
        ).to_s
      end

      def get(endpoint)
        url = api_url(endpoint)

        http = Curl.get(url, AUTH)
        JSON.load(http.body_str)
      end

      def send_request(endpoint, params={}, url_options={})
        url = api_url(endpoint, url_options)

        http = Curl.post(url, params.to_json, AUTH)
        JSON.load(http.body_str)
      end

    end

  end
end
