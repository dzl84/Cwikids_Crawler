FROM ruby:2.3.4
RUN mkdir /code
ADD . /code
WORKDIR /code
RUN bundle install
CMD ["bin/cwikids.sh"]
