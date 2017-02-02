FROM ruby:2.2.0
RUN mkdir /code
ADD . /code
WORKDIR /code
RUN bundle install
CMD ["bin/cwikids.sh"]