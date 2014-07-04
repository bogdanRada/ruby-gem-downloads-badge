module Enumerable
  def version_sort
    sort_by { |key,val|
      key.gsub(/_SP/,'.').gsub(/_Factory/,'_100').split(/_/) \
        .map { |v| v =~ /\A\d+(\.\d+)?\z/ ? -(v.to_f) : v.downcase }
    }
  end
end