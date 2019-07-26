require 'cgi'
require 'will_paginate/core_ext'
require 'will_paginate/view_helpers'
require 'will_paginate/view_helpers/link_renderer_base'

module WillPaginate
  module ViewHelpers
    # This class does the heavy lifting of actually building the pagination
    # links. It is used by +will_paginate+ helper internally.
    class LinkRenderer < LinkRendererBase
      
      # * +collection+ is a WillPaginate::Collection instance or any other object
      #   that conforms to that API
      # * +options+ are forwarded from +will_paginate+ view helper
      # * +template+ is the reference to the template being rendered
      def prepare(collection, options, template)
        super(collection, options)
        @template = template
        @container_attributes = @base_url_params = nil
      end

      # Process it! This method returns the complete HTML string which contains
      # pagination links. Feel free to subclass LinkRenderer and change this
      # method as you see fit.
      def to_html
        html = pagination.map do |item|
          item.is_a?(Integer) ?
            page_number(item) :
            send(item)
        end.join(@options[:link_separator])
        
        @options[:container] ? html_container(html) : html
      end

      # Returns the subset of +options+ this instance was initialized with that
      # represent HTML attributes for the container element of pagination links.
      def container_attributes
        @container_attributes ||= @options.except(*(ViewHelpers.pagination_options.keys + [:renderer] - [:class]))
      end
      
    protected
    
    def page_number(page)
        if page == current_page
          tag(:li, link(page, page, :rel => rel_value(page), :class => 'pagination__inner  pagination__inner--current'), :class => 'pagination__item')
        else
          tag(:li, link(page, page, :rel => rel_value(page), :class => 'pagination__inner  pagination__inner--link'), :class => 'pagination__item')
        end
      end

      def gap
        text = @template.will_paginate_translate(:page_gap) { '&hellip;' }
        %(<li class="pagination__gap">#{text}</li>)
      end

      def previous_page
        num = @collection.current_page > 1 && @collection.current_page - 1
        previous_or_next_page(num, @options[:previous_label], 'pagination__inner pagination__inner--previous')
      end

      def next_page
        num = @collection.current_page < total_pages && @collection.current_page + 1
        previous_or_next_page(num, @options[:next_label], 'pagination__inner pagination__inner--next')
      end

      def previous_or_next_page(page, text, classname)
        if page
          tag(:li, link(text, page, :class => classname + ''), :class => 'pagination__item  pagination__item--special')
        else
          tag(:li, tag(:span, text, :class => classname + '  pagination__inner--disabled'), :class => 'pagination__item  pagination__item--special')
        end
      end

      def html_container(html)
        tag(:ul, html, container_attributes)
      end
      
      # Returns URL params for +page_link_or_span+, taking the current GET params
      # and <tt>:params</tt> option into account.
      def url(page)
        raise NotImplementedError
      end
      
    private

      def param_name
        @options[:param_name].to_s
      end

      def link(text, target, attributes = {})
        if target.is_a?(Integer)
          attributes[:rel] = rel_value(target)
          target = url(target)
        end
        attributes[:href] = target
        tag(:a, text, attributes)
      end
      
      def tag(name, value, attributes = {})
        string_attributes = attributes.inject('') do |attrs, pair|
          unless pair.last.nil?
            attrs << %( #{pair.first}="#{CGI::escapeHTML(pair.last.to_s)}")
          end
          attrs
        end
        "<#{name}#{string_attributes}>#{value}</#{name}>"
      end

      def rel_value(page)
        case page
        when @collection.current_page - 1; 'prev'
        when @collection.current_page + 1; 'next'
        end
      end

      def symbolized_update(target, other, blacklist = nil)
        other.each_pair do |key, value|
          key = key.to_sym
          existing = target[key]
          next if blacklist && blacklist.include?(key)

          if value.respond_to?(:each_pair) and (existing.is_a?(Hash) or existing.nil?)
            symbolized_update(existing || (target[key] = {}), value)
          else
            target[key] = value
          end
        end
      end
    end
  end
end
