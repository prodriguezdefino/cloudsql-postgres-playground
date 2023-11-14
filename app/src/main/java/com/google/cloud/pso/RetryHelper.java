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

import com.codahale.metrics.Counter;
import com.codahale.metrics.MetricRegistry;
import dev.failsafe.Failsafe;
import dev.failsafe.FailsafeExecutor;
import dev.failsafe.RetryPolicy;
import dev.failsafe.function.CheckedRunnable;
import java.time.Duration;
import java.util.Arrays;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** */
public class RetryHelper {
  private static final Logger LOG = LoggerFactory.getLogger(RetryHelper.class);
  private static final Counter COUNTER =
      TestApplication.METRICS.counter(
          MetricRegistry.name(RetryHelper.class, "inserts.error.count"));
  private static final Counter RETRY =
      TestApplication.METRICS.counter(
          MetricRegistry.name(RetryHelper.class, "inserts.retry.count"));
  private static final Counter EXHAUST =
      TestApplication.METRICS.counter(
          MetricRegistry.name(RetryHelper.class, "inserts.exhaust.count"));

  static final Long BACKOFF_DELAY_IN_SECONDS = 5L;
  static final Long BACKOFF_MAX_DELAY_IN_MINUTES = 10L;
  static final Double RETRY_JITTER_PROB = 0.2;
  static final Integer MAX_RETRIES = 100;

  public static <T> FailsafeExecutor<T> buildRetriableExecutorForOperation(
      String operationName, Class<? extends Throwable> exClass) {
    return Failsafe.with(
        RetryPolicy.<T>builder()
            .handle(Arrays.asList(exClass))
            .withMaxAttempts(MAX_RETRIES)
            .withBackoff(
                Duration.ofSeconds(BACKOFF_DELAY_IN_SECONDS),
                Duration.ofMinutes(BACKOFF_MAX_DELAY_IN_MINUTES))
            .withJitter(RETRY_JITTER_PROB)
            .onFailedAttempt(
                e -> {
                  COUNTER.inc();
                  LOG.atError()
                      .setCause(e.getLastException())
                      .log("Execution failed for operation: {}", operationName);
                })
            .onRetry(
                r -> {
                  RETRY.inc();
                  LOG.atInfo().log(
                      "Retrying operation {}, for {} time.", operationName, r.getExecutionCount());
                })
            .onRetriesExceeded(
                e -> {
                  EXHAUST.inc();
                  LOG.atError().log("Failed to execute operation {}, retries exhausted.");
                })
            .build());
  }

  public static <T> void executeOperation(
      FailsafeExecutor<T> failsafeExecutor, CheckedRunnable runnable) {
    failsafeExecutor.run(runnable);
  }
}
