module Firebots
  module Teamwork

    class << self

      def self.new_user(user)
        params = {
          person: {
            :'first-name' user[:first_name],
            :'last-name' user[:last_name],
            :'email-address' user[:email],
            :'user-type' 'account',
            :'user-name' user[:username],
            :'company-id' '21193',
            title: '',
            :'phone-number-mobile' '',
            :'phone-number-office' '',
            :'phone-number-office-ext' '',
            :'phone-number-fax' '',
            :'phone-number-home' '',
            :'im-handle' '',
            :'im-service' '',
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

        if response = send_request('/people.json', params)['STATUS'] == 'OK'
          return {success: true}
        else
          return {success: false, erorr: response}
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

      def send_request(endpoint, params)
        url = api_url(endpoint)

        http = Curl.post(url, params.to_json.to_s) do |c|
          c.headers['Accept'] = 'application/json'
          c.headers['Content-Type'] = 'application/json'

          c.http_auth_types = :basic
          c.username = 'elbow327box'
          c.password = 'none'
        end

        JSON.load(http.body_str)
      end

    end

  end
end
