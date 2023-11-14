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

import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDateTime;
import javax.sql.DataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** */
public class SQLHelper {
  private static final Logger LOG = LoggerFactory.getLogger(SQLHelper.class);

  public static long tableRowCount(String tableName, Connection conn) throws SQLException {
    var countQuery = String.format("SELECT COUNT(*) FROM %s", tableName);
    return retrieveSingleLongResult(countQuery, conn);
  }

  public static long retrieveRandomIdFromTable(Types.TableInfo tableInfo, Connection conn)
      throws SQLException {
    var randomIdQuery =
        String.format(
            "SELECT * FROM %s OFFSET floor(random() * %d) LIMIT 1;",
            tableInfo.name(), tableInfo.count());
    return retrieveSingleLongResult(randomIdQuery, conn);
  }

  public static long retrieveSingleLongResult(String query, Connection conn) throws SQLException {
    try (var countStmt = conn.prepareStatement(query)) {
      var results = countStmt.executeQuery();
      results.next();
      return results.getLong(1);
    }
  }

  public static Types.StaticMetadata retrieveMetadata(DataSource pool) {
    try (var conn = pool.getConnection()) {
      return Types.StaticMetadata.of(
          Types.TableInfo.of("inventory", tableRowCount("inventory", conn)),
          Types.TableInfo.of("customer", tableRowCount("customer", conn)),
          Types.TableInfo.of("staff", tableRowCount("staff", conn)));
    } catch (SQLException ex) {
      LOG.atError().setCause(ex).log("Error while trying to retrieve system metadata.");
      throw new RuntimeException(ex);
    }
  }

  public static Types.Rental createRental(Types.StaticMetadata metadata, Connection conn)
      throws SQLException {
    var now = LocalDateTime.now();
    return Types.Rental.of(
        now,
        retrieveRandomIdFromTable(metadata.inventory(), conn),
        retrieveRandomIdFromTable(metadata.customer(), conn),
        now.plusDays(1),
        retrieveRandomIdFromTable(metadata.staff(), conn));
  }

  public static void storeRental(Types.Rental rental, Connection conn) throws SQLException {
    rental.createInsert(conn).execute();
  }
}
