# frozen_string_literal: true

module Ace
  module Docs
    module Atoms
      # Extracts and analyzes terminology from documents to find conflicts
      class TerminologyExtractor
        # Common words to exclude from terminology analysis
        COMMON_WORDS = %w[
          a an and are as at be but by for from has have i in is it of on or
          that the this to was will with you your we our us their them they
          can could should would may might must shall will do does did done
          get got gets getting make makes made making take takes took taken
          use uses used using go goes went gone going come comes came coming
          see sees saw seen seeing know knows knew known knowing think thinks
          thought thinking want wants wanted wanting need needs needed needing
          give gives gave given giving find finds found finding tell tells told
          telling work works worked working call calls called calling try tries
          tried trying ask asks asked asking feel feels felt feeling become
          becomes became becoming leave leaves left leaving put puts putting
          keep keeps kept keeping let lets letting begin begins began beginning
          seem seems seemed seeming help helps helped helping talk talks talked
          talking turn turns turned turning start starts started starting show
          shows showed shown showing hear hears heard hearing play plays played
          playing run runs ran running move moves moved moving like likes liked
          liking live lives lived living believe believes believed believing
          bring brings brought bringing happen happens happened happening write
          writes wrote written writing provide provides provided providing sit
          sits sat sitting stand stands stood standing lose loses lost losing
          pay pays paid paying meet meets met meeting include includes included
          including continue continues continued continuing set sets setting
          learn learns learned learning change changes changed changing lead
          leads led leading understand understands understood understanding
          watch watches watched watching follow follows followed following stop
          stops stopped stopping create creates created creating speak speaks
          spoke spoken speaking read reads reading allow allows allowed allowing
          add adds added adding spend spends spent spending grow grows grew
          grown growing open opens opened opening walk walks walked walking win
          wins won winning offer offers offered offering remember remembers
          remembered remembering love loves loved loving consider considers
          considered considering appear appears appeared appearing buy buys
          bought buying wait waits waited waiting serve serves served serving
          die dies died dying send sends sent sending expect expects expected
          expecting build builds built building stay stays stayed staying fall
          falls fell fallen falling cut cuts cutting reach reaches reached
          reaching kill kills killed killing remain remains remained remaining
          suggest suggests suggested suggesting raise raises raised raising
          pass passes passed passing sell sells sold selling require requires
          required requiring report reports reported reporting decide decides
          decided deciding pull pulls pulled pulling one two three four five
          six seven eight nine ten first second third last next new old good
          bad best worst more most less least very much many few some any all
          no not yes other another each every either neither both such own same
          different various certain several many most few little much enough
          only just still already yet even also too quite rather almost nearly
          always usually often sometimes rarely never again further then once
          now here there where when why how what which who whom whose if unless
          until while although though because since before after during within
          without through across beyond behind below beneath beside between
          above over under around among against along toward towards upon down
          up out off away back forward backward forwards backwards inside
          outside onto into about for from with without by at in on to as of
        ].freeze

        # Extract key terms from document content with frequency counts
        # @param content [String] the document content
        # @param doc_path [String] the document path for reference
        # @return [Hash] terms with their frequencies and locations
        def extract_terms(content, doc_path = nil)
          terms = {}
          lines = content.lines

          lines.each_with_index do |line, index|
            # Skip code blocks and front matter
            next if line.strip.start_with?("```", "---")

            # Extract words and normalize them
            words = line.downcase.scan(/\b[a-z]+(?:-[a-z]+)*\b/)

            words.each do |word|
              # Skip common words and very short words
              next if COMMON_WORDS.include?(word) || word.length < 3

              # Track term frequency and locations
              terms[word] ||= {count: 0, locations: [], variations: Set.new}
              terms[word][:count] += 1
              terms[word][:locations] << {file: doc_path, line: index + 1}

              # Track original variations (case)
              original = line[/\b#{Regexp.escape(word)}\b/i]
              terms[word][:variations] << original if original
            end
          end

          # Filter to meaningful terms (appears multiple times or has variations)
          terms.select do |_term, data|
            data[:count] > 1 || data[:variations].size > 1
          end
        end

        # Find terminology conflicts across multiple documents
        # @param documents [Hash] hash of { path => content }
        # @return [Array] array of conflict hashes
        def find_conflicts(documents)
          all_terms = {}
          conflicts = []

          # Extract terms from each document
          documents.each do |path, content|
            doc_terms = extract_terms(content, path)

            doc_terms.each do |term, data|
              all_terms[term] ||= {}
              all_terms[term][path] = data
            end
          end

          # Find similar terms that might be conflicts
          term_list = all_terms.keys

          term_list.each_with_index do |term1, i|
            term_list[(i + 1)..-1].each do |term2|
              similarity = calculate_similarity(term1, term2)

              # Check for potential conflicts (similar but not identical)
              if similarity > 0.7 && similarity < 1.0
                conflicts << build_conflict(term1, term2, all_terms)
              elsif are_variants?(term1, term2)
                conflicts << build_conflict(term1, term2, all_terms)
              end
            end
          end

          # Also find inconsistent usage of the same base term
          find_inconsistent_usage(all_terms, conflicts)

          conflicts.compact
        end

        # Filter out common words from a list of terms
        # @param terms [Array] list of terms to filter
        # @return [Array] filtered list without common words
        def filter_common_words(terms)
          terms.reject { |term| COMMON_WORDS.include?(term.downcase) }
        end

        private

        # Calculate similarity between two terms (simple Levenshtein-like)
        def calculate_similarity(term1, term2)
          return 1.0 if term1 == term2

          # Normalize comparison
          t1 = term1.downcase
          t2 = term2.downcase

          # Check for plural/singular variants
          return 0.95 if t1 == "#{t2}s" || t2 == "#{t1}s"
          return 0.95 if t1 == "#{t2}es" || t2 == "#{t1}es"
          return 0.95 if t1.end_with?("y") && t2 == t1[0...-1] + "ies"
          return 0.95 if t2.end_with?("y") && t1 == t2[0...-1] + "ies"

          # Check for common variations
          return 0.9 if one_char_diff?(t1, t2)

          # Otherwise, calculate based on common characters
          common_chars = (t1.chars & t2.chars).size
          max_length = [t1.length, t2.length].max.to_f
          common_chars / max_length
        end

        # Check if two terms are known variants
        def are_variants?(term1, term2)
          variants = {
            "analyze" => "analyse",
            "organize" => "organise",
            "recognize" => "recognise",
            "realize" => "realise",
            "color" => "colour",
            "behavior" => "behaviour",
            "center" => "centre",
            "fiber" => "fibre",
            "license" => "licence"
          }

          variants.any? do |us, uk|
            (term1.include?(us) && term2.include?(uk)) ||
              (term1.include?(uk) && term2.include?(us))
          end
        end

        # Check if terms differ by only one character
        def one_char_diff?(term1, term2)
          return false if (term1.length - term2.length).abs > 1

          if term1.length == term2.length
            diff_count = 0
            term1.chars.each_with_index do |char, i|
              diff_count += 1 if char != term2[i]
            end
            diff_count == 1
          else
            # Check for single insertion/deletion
            longer = (term1.length > term2.length) ? term1 : term2
            shorter = (term1.length > term2.length) ? term2 : term1

            longer.length.times do |i|
              test = longer[0...i] + longer[(i + 1)..-1]
              return true if test == shorter
            end
            false
          end
        end

        # Build a conflict report entry
        def build_conflict(term1, term2, all_terms)
          docs1 = all_terms[term1]&.keys || []
          docs2 = all_terms[term2]&.keys || []

          return nil if docs1.empty? || docs2.empty?

          {
            type: "terminology",
            terms: [term1, term2],
            documents: {
              term1 => docs1.map { |doc|
                {
                  file: doc,
                  count: all_terms[term1][doc][:count]
                }
              },
              term2 => docs2.map { |doc|
                {
                  file: doc,
                  count: all_terms[term2][doc][:count]
                }
              }
            },
            recommendation: suggest_standardization(term1, term2, all_terms)
          }
        end

        # Find inconsistent usage of the same base term
        def find_inconsistent_usage(all_terms, conflicts)
          all_terms.each do |term, docs|
            next unless docs.size > 1

            # Check if the same term has very different case variations
            all_variations = docs.values.flat_map { |d| d[:variations].to_a }
            unique_variations = all_variations.uniq

            if unique_variations.size > 1 && significantly_different_cases?(unique_variations)
              conflicts << {
                type: "case_inconsistency",
                term: term,
                variations: unique_variations,
                documents: docs.map { |path, data|
                  {
                    file: path,
                    variations: data[:variations].to_a,
                    count: data[:count]
                  }
                },
                recommendation: "Standardize capitalization of '#{term}' across documents"
              }
            end
          end
        end

        # Check if case variations are significantly different
        def significantly_different_cases?(variations)
          patterns = variations.map { |v| categorize_case(v) }.uniq
          patterns.size > 1
        end

        # Categorize the case pattern of a word
        def categorize_case(word)
          return :lower if word == word.downcase
          return :upper if word == word.upcase
          return :title if word == word.capitalize
          :mixed
        end

        # Suggest which term to standardize on
        def suggest_standardization(term1, term2, all_terms)
          # Prefer the more frequently used term
          count1 = all_terms[term1]&.values&.sum { |d| d[:count] } || 0
          count2 = all_terms[term2]&.values&.sum { |d| d[:count] } || 0

          if count1 > count2 * 2
            "Standardize to '#{term1}' (used #{count1} times vs #{count2})"
          elsif count2 > count1 * 2
            "Standardize to '#{term2}' (used #{count2} times vs #{count1})"
          elsif are_variants?(term1, term2)
            # Check for US vs UK spelling
            if term1.include?("z") || term1.include?("or")
              "Standardize to '#{term1}' (US spelling)"
            else
              "Standardize to '#{term2}' (UK spelling)"
            end
          else
            "Consider standardizing to '#{(count1 >= count2) ? term1 : term2}'"
          end
        end
      end
    end
  end
end
