module ActiveRecord
  class Base
    def is_liker?
      false
    end
  end
end

module Potter
  module Liker
    extend ActiveSupport::Concern

    included do
      # A like is the Like record of self liking a likeable record.
      has_many :likes, :as => :liker, :dependent => :destroy, :class_name => 'Like'

      def is_liker?
        true
      end

      def like!(likeable)
        ensure_likeable!(likeable)
        raise ArgumentError, "#{self} cannot like itself!" unless self != likeable
        ll = likeable.likings.where(:liker_type => self.class.to_s, :liker_id => self.id)
        unless ll.empty?
          #ll.each { |l| l.destroy }
          ll.each { |l| 
                    l.dislike = false
                    l.save 
                  }
        else
          Like.create!({ :liker => self, :likeable => likeable, :dislike=>false }, :without_protection => true)     
        end
      end
      
      def dislike!(likeable)
        ensure_likeable!(likeable)
        raise ArgumentError, "#{self} cannot like itself!" unless self != likeable
        ll = likeable.likings.where(:liker_type => self.class.to_s, :liker_id => self.id)
        unless ll.empty?
          #ll.each { |l| l.destroy }
          ll.each { |l| 
                    l.dislike = true
                    l.save 
                  }
        else
          Like.create!({ :liker => self, :likeable => likeable, :dislike=>true }, :without_protection => true)     
        end
          
      end

      def no_opinion!(likeable)
        ensure_likeable!(likeable)
        raise ArgumentError, "#{self} cannot like itself!" unless self != likeable
        ll = likeable.likings.where(:liker_type => self.class.to_s, :liker_id => self.id)
        unless ll.empty?
          ll.each { |l| l.destroy }
          #ll.each { |l| 
          #          l.dislike = true
          #          l.save 
          #        }
       # else
        #  Like.create!({ :liker => self, :likeable => likeable, :dislike=>true }, :without_protection => true)     
         raise ActiveRecord::RecordNotFound
        end
          
      end

      def unlike!(likeable)
        ll = likeable.likings.where(:liker_type => self.class.to_s, :liker_id => self.id)
        unless ll.empty?
          #ll.each { |l| l.destroy }
          ll.each { |l| 
                    l.dislike = true
                    l.save 
                  }
        else
          raise ActiveRecord::RecordNotFound
        end
      end

      def likes?(likeable)
        ensure_likeable!(likeable)
        !self.likes.where(:likeable_type => likeable.class.to_s, :likeable_id => likeable.id, :dislike => false).empty?
      end
      
      # Toggles a {LikeStore like} relationship.
      #
      # @param [Likeable] likeable the object to like/unlike.
      # @return [Boolean]
      def toggle_like!(likeable)
        if likes?(likeable)
          unlike!(likeable)
          false
        else
          like!(likeable)
          true
        end
      end

      def likees(klass)
        klass = klass.to_s.singularize.camelize.constantize unless klass.is_a?(Class)
        klass.joins("INNER JOIN likes ON likes.likeable_id = #{klass.to_s.tableize}.id AND likes.likeable_type = '#{klass.to_s}'").
              where("likes.liker_type = '#{self.class.to_s}'").
              where("likes.liker_id   =  #{self.id}")
      end

      private
        def ensure_likeable!(likeable)
          raise ArgumentError, "#{likeable} is not likeable!" unless likeable.is_likeable?
        end
    end
  end
end
