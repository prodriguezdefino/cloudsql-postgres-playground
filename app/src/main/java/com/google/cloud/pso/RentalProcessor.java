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

import com.codahale.metrics.Histogram;
import com.codahale.metrics.MetricRegistry;
import java.sql.SQLException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** */
public class RentalProcessor implements Runnable {
  private static final Logger LOG = LoggerFactory.getLogger(SQLHelper.class);

  private static final Histogram HISTOGRAM =
      TestApplication.METRICS.histogram(
          MetricRegistry.name(RentalProcessor.class, "inserts.latency.ms"));

  private final Types.StaticMetadata metadata;

  public RentalProcessor(Types.StaticMetadata metadata) {
    this.metadata = metadata;
  }

  public static RentalProcessor of(Types.StaticMetadata metadata) {
    return new RentalProcessor(metadata);
  }

  @Override
  public void run() {
    var failsafe =
        RetryHelper.buildRetriableExecutorForOperation("storeRental", SQLException.class);
    while (true) {
      try {
        var start = System.currentTimeMillis();
        RetryHelper.executeOperation(failsafe, () -> process());
        HISTOGRAM.update(System.currentTimeMillis() - start);
      } catch (Exception ex) {
        LOG.atError().setCause(ex).log("Problems while processing rental insert, continue...");
      }
    }
  }

  void process() throws SQLException {
    try (var conn = ConnectionPool.get().getConnection()) {
      SQLHelper.storeRental(SQLHelper.createRental(metadata, conn), conn);
    }
  }
}
