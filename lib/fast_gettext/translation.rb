module FastGettext
  # this module should be included
  # Responsibility:
  #  - direct translation queries to the current repository
  #  - handle untranslated values
  #  - understand / enforce namespaces
  #  - decide which plural form is used
  module Translation
    extend self

    #make it usable in class definition, e.g.
    # class Y
    #   include FastGettext::Translation
    #   @@x = _('y')
    # end
    def self.included(klas)  #:nodoc:
      klas.extend self
    end

    def _(key)
      translation = FastGettext.cached_find(key)
      unless translation
        FastGettext.missing_translation_callback[:model_name].constantize.send(FastGettext.missing_translation_callback[:function_name], key, FastGettext.locale) if FastGettext.missing_translation_callback
        if FastGettext.default_locale && FastGettext.default_locale.to_sym != FastGettext.locale.to_sym
          locale = FastGettext.locale
          FastGettext.locale = FastGettext.default_locale
          translation = _(key)
          FastGettext.locale = locale
        else
          translation = key
        end
      end
      translation
    end

    #translate pluralized
    # some languages have up to 4 plural forms...
    # n_(singular, plural, plural form 2, ..., count)
    # n_('apple','apples',3)
    def n_(*keys)
      count = keys.pop
      translations = FastGettext.cached_plural_find(*keys)

      selected = FastGettext.pluralisation_rule.call(count)
      selected = (selected ? 1 : 0) unless selected.is_a? Numeric #convert booleans to numbers

      result = translations[selected]
      if result
        result
      elsif keys[selected]
        _(keys[selected])
      else
        keys.last
      end
    end

    #translate, but discard namespace if nothing was found
    # Car|Tire -> Tire if no translation could be found
    def s_(key,separator=nil)
      translation = FastGettext.cached_find(key) and return translation
      key.split(separator||NAMESPACE_SEPARATOR).last
    end

    #tell gettext: this string need translation (will be found during parsing)
    def N_(translate)
      translate
    end

    #tell gettext: this string need translation (will be found during parsing)
    def Nn_(*keys)
      keys
    end

    def ns_(*args)
      n_(*args).split(NAMESPACE_SEPARATOR).last
    end
  end
end
