# Use an official Ruby runtime as a parent image
FROM ruby:3.2.2

# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

# Install gems
RUN gem install bundler
RUN bundle install --without development test

# Copy the rest of the application code
COPY . /app

# Expose port 9292 for the application
EXPOSE 9292

# Start the application
CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0"]
