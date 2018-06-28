require 'rails_helper'

def send_data(params)
  @request.env['RAW_POST_DATA'] = params.to_json
  post :create
end

RSpec.describe Api::V1::HooksController, type: :controller do
  #routes { Engine.routes }
  
  let(:app){ FactoryGirl.create(:app) }
  let(:subscriber){
    app.add_user(email: Faker::Internet.email, properties: { 
          custom_country: "albania",
          name: Faker::Name.unique.name 
        })
  }

  let(:campaign){ FactoryGirl.create(:campaign, app: app) }

  let(:metric){
    FactoryGirl.create(:metric, 
      campaign: campaign, 
      trackable: subscriber
    )
  }

  let(:bounce_sns){
     {"Message" => {
           "notificationType"=>"Bounce",
           "bounce"=>{
              "bounceType"=>"Permanent",
              "bounceSubType"=> "General",
              "bouncedRecipients"=>[
                 {
                    "emailAddress"=>"#{subscriber.email}"
                 },
                 {
                    "emailAddress"=>"recipient2@example.com"
                 }
              ],
              "timestamp"=>"2012-05-25T14:59:38.237-07:00",
              "feedbackId"=>"00000137860315fd-869464a4-8680-4114-98d3-716fe35851f9-000000"
           },
           "mail"=>{
              "timestamp"=>"2012-05-25T14:59:38.237-07:00",
              "messageId"=>"00000137860315fd-34208509-5b74-41f3-95c5-22c1edc3c924-000000",
              "source"=>"#{campaign.from_email}",
              "destination"=>[
                 "recipient1@example.com",
                 "recipient2@example.com",
                 "recipient3@example.com",
                 "recipient4@example.com"
              ]
          }
        }.to_json
      }
  }

  let(:complaint_sns){
    {"Message" => {
        "notificationType"=>"Complaint",
        "complaint"=>{
           "complainedRecipients"=>[
              {
                 "emailAddress"=>"#{subscriber.email}"
              }
           ],
           "timestamp"=>"2012-05-25T14:59:38.613-07:00",
           "feedbackId"=>"0000013786031775-fea503bc-7497-49e1-881b-a0379bb037d3-000000"
        },
        "mail"=>{
           "timestamp"=>"2012-05-25T14:59:38.613-07:00",
           "messageId"=>"0000013786031775-163e3910-53eb-4c8e-a04a-f29debf88a84-000000",
           "source"=>"#{campaign.from_email}",
           "destination"=>[
              "recipient1@example.com",
              "recipient2@example.com",
              "recipient3@example.com",
              "recipient4@example.com"
           ]
        }
      }.to_json
    }
  }

  let(:delivery_sns){
    JSON.parse('{
      "eventType": "Delivery",
      "mail": {
        "timestamp": "2016-10-19T23:20:52.240Z",
        "source": "sender@example.com",
        "sourceArn": "arn:aws:ses:us-east-1:123456789012:identity/sender@example.com",
        "sendingAccountId": "123456789012",
        "messageId": "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000",
        "destination": [
          "recipient@example.com"
        ],
        "headersTruncated": false,
        "headers": [
          {
            "name": "From",
            "value": "sender@example.com"
          },
          {
            "name": "To",
            "value": "recipient@example.com"
          },
          {
            "name": "Subject",
            "value": "Message sent from Amazon SES"
          },
          {
            "name": "MIME-Version",
            "value": "1.0"
          },
          {
            "name": "Content-Type",
            "value": "text/html; charset=UTF-8"
          },
          {
            "name": "Content-Transfer-Encoding",
            "value": "7bit"
          }
        ],
        "commonHeaders": {
          "from": [
            "sender@example.com"
          ],
          "to": [
            "recipient@example.com"
          ],
          "messageId": "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000",
          "subject": "Message sent from Amazon SES"
        },
        "tags": {
          "ses:configuration-set": [
            "ConfigSet"
          ],
          "ses:source-ip": [
            "192.0.2.0"
          ],
          "ses:from-domain": [
            "example.com"
          ],
          "ses:caller-identity": [
            "ses_user"
          ],
          "ses:outgoing-ip": [
            "192.0.2.0"
          ],
          "myCustomTag1": [
            "myCustomTagValue1"
          ],
          "myCustomTag2": [
            "myCustomTagValue2"
          ]      
        }
      },
      "delivery": {
        "timestamp": "2016-10-19T23:21:04.133Z",
        "processingTimeMillis": 11893,
        "recipients": [
          "recipient@example.com"
        ],
        "smtpResponse": "250 2.6.0 Message received",
        "reportingMTA": "mta.example.com"
      }
    }')
  }

  let(:send_sns){
    JSON.parse('{
      "eventType": "Send",
      "mail": {
        "timestamp": "2016-10-14T05:02:16.645Z",
        "source": "sender@example.com",
        "sourceArn": "arn:aws:ses:us-east-1:123456789012:identity/sender@example.com",
        "sendingAccountId": "123456789012",
        "messageId": "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000",
        "destination": [
          "recipient@example.com"
        ],
        "headersTruncated": false,
        "headers": [
          {
            "name": "From",
            "value": "sender@example.com"
          },
          {
            "name": "To",
            "value": "recipient@example.com"
          },
          {
            "name": "Subject",
            "value": "Message sent from Amazon SES"
          },
          {
            "name": "MIME-Version",
            "value": "1.0"
          },
          {
            "name": "Content-Type",
            "value": "multipart/mixed;  boundary=\"----=_Part_0_716996660.1476421336341\""
          },
          {
            "name": "X-SES-MESSAGE-TAGS",
            "value": "myCustomTag1=myCustomTagValue1, myCustomTag2=myCustomTagValue2"
          }
        ],
        "commonHeaders": {
          "from": [
            "sender@example.com"
          ],
          "to": [
            "recipient@example.com"
          ],
          "messageId": "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000",
          "subject": "Message sent from Amazon SES"
        },
        "tags": {
          "ses:configuration-set": [
            "ConfigSet"
          ],
          "ses:source-ip": [
            "192.0.2.0"
          ],
          "ses:from-domain": [
            "example.com"
          ],      
          "ses:caller-identity": [
            "ses_user"
          ],
          "myCustomTag1": [
            "myCustomTagValue1"
          ],
          "myCustomTag2": [
            "myCustomTagValue2"
          ]      
        }
      },
      "send": {}
    }
    ')
  }

  let(:open_sns){
    JSON.parse('{
      "eventType": "Open",
      "mail": {
        "commonHeaders": {
          "from": [
            "sender@example.com"
          ],
          "messageId": "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000",
          "subject": "Message sent from Amazon SES",
          "to": [
            "recipient@example.com"
          ]
        },
        "destination": [
          "recipient@example.com"
        ],
        "headers": [
          {
            "name": "X-SES-CONFIGURATION-SET",
            "value": "ConfigSet"
          },
          {
            "name": "From",
            "value": "sender@example.com"
          },
          {
            "name": "To",
            "value": "recipient@example.com"
          },
          {
            "name": "Subject",
            "value": "Message sent from Amazon SES"
          },
          {
            "name": "MIME-Version",
            "value": "1.0"
          },
          {
            "name": "Content-Type",
            "value": "multipart/alternative; boundary=\"XBoundary\""
          }
        ],
        "headersTruncated": false,
        "messageId": "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000",
        "sendingAccountId": "123456789012",
        "source": "sender@example.com",
        "tags": {
          "ses:caller-identity": [
            "ses-user"
          ],
          "ses:configuration-set": [
            "ConfigSet"
          ],
          "ses:from-domain": [
            "example.com"
          ],
          "ses:source-ip": [
            "192.0.2.0"
          ]
        },
        "timestamp": "2017-08-09T21:59:49.927Z"
      },
      "open": {
        "ipAddress": "192.0.2.1",
        "timestamp": "2017-08-09T22:00:19.652Z",
        "userAgent": "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_3 like Mac OS X) AppleWebKit/603.3.8 (KHTML, like Gecko) Mobile/14G60"
      }
    }')
  }

  let(:click_sns){
    JSON.parse('{
      "eventType": "Click",
      "click": {
        "ipAddress": "192.0.2.1",
        "link": "http://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-smtp.html",
        "linkTags": {
          "samplekey0": [
            "samplevalue0"
          ],
          "samplekey1": [
            "samplevalue1"
          ]
        },
        "timestamp": "2017-08-09T23:51:25.570Z",
        "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36"
      },
      "mail": {
        "commonHeaders": {
          "from": [
            "sender@example.com"
          ],
          "messageId": "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000",
          "subject": "Message sent from Amazon SES",
          "to": [
            "recipient@example.com"
          ]
        },
        "destination": [
          "recipient@example.com"
        ],
        "headers": [
          {
            "name": "X-SES-CONFIGURATION-SET",
            "value": "ConfigSet"
          },
          {
            "name": "From",
            "value": "sender@example.com"
          },
          {
            "name": "To",
            "value": "recipient@example.com"
          },
          {
            "name": "Subject",
            "value": "Message sent from Amazon SES"
          },
          {
            "name": "MIME-Version",
            "value": "1.0"
          },
          {
            "name": "Content-Type",
            "value": "multipart/alternative; boundary=\"XBoundary\""
          },
          {
            "name": "Message-ID",
            "value": "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000"
          }
        ],
        "headersTruncated": false,
        "messageId": "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000",
        "sendingAccountId": "123456789012",
        "source": "sender@example.com",
        "tags": {
          "ses:caller-identity": [
            "ses_user"
          ],
          "ses:configuration-set": [
            "ConfigSet"
          ],
          "ses:from-domain": [
            "example.com"
          ],
          "ses:source-ip": [
            "192.0.2.0"
          ]
        },
        "timestamp": "2017-08-09T23:50:05.795Z"
      }
    }
    ')
  }



  it "will set a bounce" do
    inline_job do
      allow(Metric).to receive(:find_by).and_return(metric)
      campaign
      response = send_data(bounce_sns)
      expect(response.status).to be == 200
      expect(campaign.metrics.bounces.size).to be == 1
    end
  end

  it "will set a spam metric and unsubscribe user" do
    inline_job do
      ActiveJob::Base.queue_adapter = :inline
      allow(Metric).to receive(:find_by).and_return(metric)

      campaign
      response = send_data(complaint_sns)
      expect(response.status).to be == 200
      expect(campaign.metrics.spams.size).to be == 1
      expect(subscriber.reload).to be_unsubscribed
    end
  end
end