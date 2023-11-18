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

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.util.Optional;
import javax.sql.DataSource;

/** */
public class ConnectionPool {

  private static DataSource INSTANCE = null;

  public static synchronized DataSource initialize(
      String instanceHost, String port, String dbName, String user, String password) {
    if (INSTANCE == null) {
      var config = new HikariConfig();

      config.setJdbcUrl(String.format("jdbc:postgresql://%s:%s/%s", instanceHost, port, dbName));
      config.addDataSourceProperty("user", user);
      config.addDataSourceProperty("password", password);
      config.addDataSourceProperty("sslmode", "disable");
      configureConnectionPool(config);

      INSTANCE = new HikariDataSource(config);
    }
    return INSTANCE;
  }

  public static DataSource get() {
    return Optional.ofNullable(INSTANCE)
        .orElseThrow(() -> new RuntimeException("Datasource not initialized."));
  }

  static HikariConfig configureConnectionPool(HikariConfig config) {
    config.setMaximumPoolSize(150);
    config.setMinimumIdle(5);
    config.setConnectionTimeout(10000); // 10 seconds
    config.setIdleTimeout(600000); // 10 minutes
    config.setMaxLifetime(1800000); // 30 minutes
    return config;
  }
}