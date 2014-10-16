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

        # get the person's id from the header response
        id = response.header_str.split("\r\n").select do |h|
          h.start_with?('id: ')
        end.first.gsub(/\D/, '')

        response = JSON.load(response.body_str)

        if response['STATUS'] == 'OK'
          add_to_projects(id)

          {
            success: true,
            response: response,
          }
        else
          {
            success: false,
            erorr: response,
          }
        end
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

      def api_url(endpoint, params={})
        URI.const_get(API_PROTOCOL).build(
          host: API_HOST,
          path: endpoint,
          query: params.empty? ? nil : URI.encode_www_form(params),
        ).to_s
      end

      def get(endpoint)
        url = api_url(endpoint)

        http = Curl.get(url) do |c|
          c.headers['Accept'] = 'application/json'
          c.headers['Content-Type'] = 'application/json'

          c.http_auth_types = :basic
          c.username = Konfiguration.creds(:teamwork, :username)
          c.password = 'none'
        end

        JSON.load(http.body_str)
      end

      def send_request(endpoint, params={}, url_options={})
        url = api_url(endpoint, url_options)

        http = Curl.post(url, params.to_json) do |c|
          c.headers['Accept'] = 'application/json'
          c.headers['Content-Type'] = 'application/json'

          c.http_auth_types = :basic
          c.username = Konfiguration.creds(:teamwork, :username)
          c.password = 'none'
        end

        http
      end

    end

  end
end
