module BananaScrum
  module Shoulda
    module SslChecks

      def should_include_check_ssl_filter
        # This method is left empty, as we don't need this functionality in
        # box version
      end

      def should_redirect_to_https_protocol_if_enabled
        # This method is left empty, as we don't need this functionality in
        # box version
      end

      # cutom macros for checking ssl redirections
      def should_not_redirect
        should "not redirect" do
          @controller.expects(:redirect_to).never
          @controller.send(:handle_ssl)
        end
      end

      def should_redirect_to_https_protocol
        should "redirect to https protocol" do
          @controller.expects(:redirect_to).with({:protocol => 'https://'})
          @controller.send(:handle_ssl)
        end
      end

      def should_redirect_to_http_protocol
        should "redirect to http protocol" do
          @controller.expects(:redirect_to).with({:protocol => 'http://'})
          @controller.send(:handle_ssl)
        end
      end

    end
  end
end

ActiveSupport::TestCase.extend(BananaScrum::Shoulda::SslChecks)
