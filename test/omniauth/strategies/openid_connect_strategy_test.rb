require 'test_helper'
class OpenIDConnectStrategyTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include OmniAuth::Test::StrategyTestCase
  include WebMock::API
  
  def strategy
    # return the parameters to a Rack::Builder map call:
    [OmniAuth::Strategies::OpenIDConnect,"localhost","my_id","my_s",{client_options:{scheme:"https", port:nil}}]
  end

  def setup
    # @strat = create_client("http://localhost", "my_id","my_secret" )
  end
  
  def test_authorization_request
    get '/auth/openid_connect'
    assert last_response.status == 302
    uri = URI.parse(last_response.headers["Location"])
    assert uri.host == "localhost"
    assert uri.scheme == "https"
    assert uri.query.index("client_id=my_id"), "client id "
  end
  
  
  def test_callback
    
    get '/auth/openid_connect'
    @nonce = session[:nonce]
    # Mock a web request location that will return info for a check_id request
    stub_request(:get,'https://localhost/check_id').to_return(:body =><<-eos
    {
     "iss": "https://localhost",
     "user_id": "248289761001",
     "aud": "my_id",
     "nonce": "#{@nonce}",
     "exp": 9911281970,
     "iat": 1311280970
    }
   eos
    )
     stub_request(:post,'https://localhost/token').to_return( :body=><<-eos
      {
       "access_token": "SlAV32hkKG",
       "token_type": "Bearer",
       "refresh_token": "8xLOxBtZp8",
       "expires_in": 3600,
       "id_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOlwvXC9zZXJ2ZXIuZXhhbXBsZS5jb20iLCJ1c2VyX2lkIjoiMjQ4Mjg5NzYxMDAxIiwiYXVkIjoiaHR0cDpcL1wvY2xpZW50LmV4YW1wbGUuY29tIiwiZXhwIjoxMzExMjgxOTcwfQ.eDesUD0vzDH3T1G3liaTNOrfaeWYjuRCEPNXVtaazNQ"
      }
      eos

      )
      
      
     stub_request(:get,'https://localhost/user_info').to_return( :body=><<-eos
     {
      "user_id": "248289761001",
      "name": "Jane Doe",
      "given_name": "Jane",
      "family_name": "Doe",
      "email": "janedoe@example.com",
      "picture": "http://example.com/janedoe/me.jpg"
     }
      eos

      )
    
    get '/auth/openid_connect/callback', {code:"Qcb0Orv1zh30vL1MPRsbm-diHiMwcLyZvn1arpZv-Jxf_11jnpEX3Tgfvk", state:"af0ifjsldkj"}
    
    
  end
  

  
  def test_user_info
     # Mock a web request location that will return info for a user_info  request
  end
  
  
  def test_configuration
     client = create_client("http://localhost", "my_id","my_secret" )
     assert_equal "http://localhost", client.options.host
     assert_equal "my_id", client.options.client_id
     assert_equal "my_secret", client.options.client_secret  
  end
  
end
