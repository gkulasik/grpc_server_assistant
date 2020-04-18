class ServiceController < ApplicationController
  # See get_grpc_headers comment for more information
  GRPC_HEADER_PREFIX = "HTTP_GRPC_"

  # Execute a given grpcurl command given input, returns command and result
  # Route: service_execute
  # Path: POST /service/execute
  def execute
    # update tests
    # figure out how to get grpcurl into docker and link protos to it
    headers = get_grpc_headers(request.headers)
    builder = GrpcurlBuilder.from_params(headers, service_params.to_hash)
    if builder.valid?
      result = GrpcurlExecutor.execute(builder)
      status = result.is_success? ? :ok : :bad_request
      render json: result.to_api_response, status: status
    else
      render json: { errors: builder.errors }, status: :bad_request
    end
  end

  # Get a grpcurl command given input, returns command only (no execution)
  # Route: service_command
  # Path: POST /service/command
  def command
    headers = get_grpc_headers(request.headers)
    builder = GrpcurlBuilder.from_params(headers, service_params.to_hash)
    if builder.valid?
      render json: { command: builder.build }, status: :ok
    else
      render json: { errors: builder.errors }, status: :bad_request
    end
  end

  # Helper to get all grpc headers.
  # Postman prefixes headers with HTTP_ and in order to differentiate from other HTTP headers we add GRPC_ to the prefix (making HTTP_GRPC_...)
  # This gets all those headers and strips them down to the actual header name without  prefix (so HTTP_GRPC_AUTHORIZATION -> auth-code becomes AUTHORIZATION -> auth-code).
  # @param [Hash] headers_hash
  # @return [Hash]
  def get_grpc_headers(headers_hash)
    headers_hash.select { |k, v| k.include? GRPC_HEADER_PREFIX }.map { |k, v| [k.gsub(GRPC_HEADER_PREFIX, ""), v] }.to_h
  end

  # Permit only certain params but then allow all data from :data to allow variable data to be submitted to grpc servers.
  # @return [ActionController::Parameters]
  def service_params
    allowed_params = params.permit(:options,
                  :server_address,
                  :service_name,
                  :method_name,
                  :data,
                  options: [:verbose, :import_path, :service_proto_path, :insecure])
    allowed_params[:data] = params[:data]
    allowed_params.permit!
  end

end
