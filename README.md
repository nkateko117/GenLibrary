<h1 align="center">Project Documentation and Specifications</h1>

## Tech Stack
- ASP.Net Core 10 MVC
- Microsoft SQL Database.
- Claude Opus 4.5 (Preview) was used through copilot for assistance with writing repetative code quicker.

## How To Run The Project
- You first need to run the database script: root/DbScripts/00_ConsolidatedSetup.sql
- When running the project, the following users will automatically be seeded to the database:

<table>
    <thead>
      <tr>
        <th>Email (Username)</th>
        <th>Password</th>
        <th>System Role</th>
     </tr>  
    </thead>
    <tbody>
      <tr>
        <td>librarian@library.local</th>
        <td>P@ssw0rd!</th>
        <td>Librarian</th>
     </tr>
    <tr>
        <td>john.doe@library.local</th>
        <td>P@ssw0rd!</th>
        <td>Member</th>
     </tr>
    <tr>
        <td>jane.smith@library.local</th>
        <td>P@ssw0rd!</th>
        <td>Member</th>
     </tr>
    <tr>
        <td>mike.wilson@library.local</th>
        <td>P@ssw0rd!</th>
        <td>Member</th>
     </tr>
    </tbody>
  </table>
  
## Design Patterns
- Summary:

<table>
    <thead>
      <tr>
        <th>ASPECT</th>
        <th>PATTERN USED</th>
     </tr>  
    </thead>
    <tbody>
      <tr>
        <td>Overall Architecture</th>
        <td>Simplified N-Tier / Layered</th>
     </tr>
    <tr>
        <td>Presentation</th>
        <td>ASP.NET Core MVC (Controllers + Razor Views)</th>
     </tr>
    <tr>
        <td>Service Layer</th>
        <td>Service classes with interfaces (DI)</th>
     </tr>
    <tr>
        <td>Data Access</th>
        <td>ADO.NET with Stored Procedures</th>
     </tr>
    <tr>
        <td>Identity</th>
        <td>Custom Identity Stores (not EF Identity)</th>
     </tr>
    <tr>
        <td>Database</th>
        <td>SQL Server with Views + Stored Procedures</th>
     </tr>
    </tbody>
  </table>
  
