/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 

# We add `id` as an alias to `name` to simplify log sink handling.
# Since all other log destinations (pubsub, logging-bucket, bigquery)
# have an id output, it is convenient to have in this module too to
# handle all log destination as homogeneous objects (i.e. you can
# assume any valid log destination has an `id` output).