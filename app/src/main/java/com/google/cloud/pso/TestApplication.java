/*
 * Copyright (C) 2023 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

package com.google.cloud.pso;

import com.codahale.metrics.ConsoleReporter;
import com.codahale.metrics.MetricRegistry;
import java.io.IOException;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.stream.IntStream;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** */
public class TestApplication {
  public static final MetricRegistry METRICS = new MetricRegistry();

  private static final Logger LOG = LoggerFactory.getLogger(TestApplication.class);

  public static void main(String[] args) {

    try {
      var parsedArgs =
          new DefaultParser()
              .parse(
                  new Options()
                      .addOption(Option.builder("db").argName("db").hasArg().required().build())
                      .addOption(Option.builder("usr").argName("usr").hasArg().required().build())
                      .addOption(Option.builder("pwd").argName("pwd").hasArg().required().build())
                      .addOption(
                          Option.builder("parallelism")
                              .argName("parallelism")
                              .hasArg()
                              .optionalArg(true)
                              .build())
                      .addOption(
                          Option.builder("instance")
                              .argName("instance")
                              .hasArg()
                              .required()
                              .build()),
                  args);
      var pool =
          IAMConnectionPool.initialize(
              parsedArgs.getOptionValue("db"),
              parsedArgs.getOptionValue("usr"),
              parsedArgs.getOptionValue("pwd"),
              parsedArgs.getOptionValue("instance"));
      setupMetrics();
      var parallelism = Integer.valueOf(parsedArgs.getOptionValue("parallelism", "100"));

      Types.StaticMetadata metadata = SQLHelper.retrieveMetadata(pool);

      try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        IntStream.range(0, parallelism).forEach(i -> executor.submit(RentalProcessor.of(metadata)));
        executor.awaitTermination(1, TimeUnit.DAYS);
      } catch (InterruptedException ex) {
        LOG.atError().setCause(ex).log(ex.getMessage());
      }
    } catch (ParseException | IOException ex) {
      LOG.atError().setCause(ex).log(ex.getMessage());
    }
  }

  static void setupMetrics() throws IOException {
    var reporter =
        ConsoleReporter.forRegistry(METRICS)
            .convertRatesTo(TimeUnit.SECONDS)
            .convertDurationsTo(TimeUnit.MILLISECONDS)
            .build();
    reporter.start(30, TimeUnit.SECONDS);
  }
}
