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
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDateTime;

/** */
public interface Types {
  record TableInfo(String name, long count) {
    public static TableInfo of(String name, long count) {
      return new TableInfo(name, count);
    }
  }

  record StaticMetadata(TableInfo inventory, TableInfo customer, TableInfo staff) {
    public static StaticMetadata of(TableInfo inventory, TableInfo customer, TableInfo staff) {
      return new StaticMetadata(inventory, customer, staff);
    }
  }

  record Rental(
      LocalDateTime rental,
      Long inventoryId,
      Long customerId,
      LocalDateTime returned,
      Long staffId) {

    public PreparedStatement createInsert(Connection conn) throws SQLException {
      var insert =
          """
          INSERT INTO rental
          (rental_date, inventory_id, customer_id, return_date, staff_id)
          VALUES (?,?,?,?,?)
          """;
      var stmt = conn.prepareStatement(insert);
      stmt.setObject(1, rental());
      stmt.setInt(2, inventoryId().intValue());
      stmt.setInt(3, customerId().intValue());
      stmt.setObject(4, returned());
      stmt.setInt(5, staffId().intValue());
      return stmt;
    }

    public static Rental of(
        LocalDateTime rental,
        long inventoryId,
        long customerId,
        LocalDateTime returned,
        long staffId) {
      return new Rental(rental, inventoryId, customerId, returned, staffId);
    }
  }
}
