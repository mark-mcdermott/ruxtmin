class UploadsController < ApplicationController
  before_action :authenticate_user! # Ensure you have authentication in place

  def presigned_url
    filename = params[:filename]
    content_type = params[:content_type]

    s3_client = Aws::S3::Client.new(region: 'your-region')
    presigned_url = s3_client.presigned_url(:put_object,
      bucket: 'qa-applicant-portal',
      key: filename,
      content_type: content_type,
      acl: 'public-read' # Adjust ACL as needed
    )

    render json: { url: presigned_url }
  end
end