---
description: Functional requirements of the system.
---

# Functional requirements

### User management

1. The systems shall allow the user to create an account by providing the following information: username, email, password.
2. The system shall allow the user to login to the system in the following ways:
   1. Username and password pair.
   2. Email and password pair (interchangeable with method 1).
   3. Google account though single sign-on process.
3. The system shall allow the user to recover forgotten password by sending the recovery link to the email, if such is found.&#x20;

### Book management

1. The system shall allow the user to upload book files from the filesystem of their device.
2. The system shall allow the user to search uploaded files by the following attributes:
   1. Title
   2. Author
   3. Publisher
   4. Publication date
   5. ISBN number
   6. Tags
3. The system shall index contents of the uploaded books for full text search.
4. The system shall apply OCR for any scanned files to make them available for indexing and searching through full text search.
5. The system shall allow the user to create shelves to group available books.
6. The system shall allow the user to assign tags to the book. Tag consists of title and color. The book may have from 0 to 10 unique tags.

### Insights

1. The system shall track time spent reading the book and pages read.
2. The system shall allow the user to view the following statistics for all or only selected books:
   1. Time spent reading.
   2. Books read.
   3. Pages read.
   4. Time spent per page.
3. The system shall allow the user to filter statistics display by the following attributes:
   1. Books
      1. All books
      2. Selected books.
   2. Time interval.
      1. Custom interval.
      2. Last week.
      3. Last month.
      4. Last year.

