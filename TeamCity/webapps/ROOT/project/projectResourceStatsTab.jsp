<%--@elvariable id="data24" type="jetbrains.buildServer.serverSide.statistics.buildtime.BuildTimeInfo"--%>
<%--@elvariable id="dataWeek" type="jetbrains.buildServer.serverSide.statistics.buildtime.BuildTimeInfo"--%>
<%--@elvariable id="dataMonth" type="jetbrains.buildServer.serverSide.statistics.buildtime.BuildTimeInfo"--%>
<%@ include file="/include-internal.jsp" %>
<bs:linkScript>
  /js/bs/resourceStatistics.js
</bs:linkScript>
<h3>Build Time</h3>
<table>
  <thead>
  <tr>
    <th>&nbsp;</th>
    <th>total duration</th>
    <th>number of builds</th>
    <th>average duration</th>
    <th>longest build # (duration)</th>
    <th>shortest build # (duration)</th>
  </tr>
  </thead>
  <tbody>
  <tr>
    <td>last 24 h</td>
    <td><bs:printTime time="${data24.duration / 1000}"/></td>
    <td>${data24.count}</td>
    <td><bs:printTime time="${data24.average / 1000}"/></td>
    <td>${data24.longest.buildId}::${data24.longest.buildNumber} (<bs:printTime time="${data24.longest.duration / 1000}"/>)</td>
    <td>${data24.shortest.buildId}::${data24.shortest.buildNumber}(<bs:printTime time="${data24.shortest.duration / 1000}"/>)</td>
  </tr>
  <tr>
    <td>last week</td>
    <td><bs:printTime time="${dataWeek.duration / 1000}"/></td>
    <td>${dataWeek.count}</td>
    <td><bs:printTime time="${dataWeek.average / 1000}"/></td>
    <td>${dataWeek.longest.buildId}::${dataWeek.longest.buildNumber} (<bs:printTime time="${dataWeek.longest.duration / 1000}"/>)</td>
    <td>${dataWeek.shortest.buildId}::${dataWeek.shortest.buildNumber} (<bs:printTime time="${dataWeek.shortest.duration / 1000}"/>)</td>
  </tr>
  <tr>
    <td>last month</td>
    <td><bs:printTime time="${dataMonth.duration / 1000}"/></td>
    <td>${dataMonth.count}</td>
    <td><bs:printTime time="${dataMonth.duration / 1000 / dataMonth.count}"/></td>
    <td>${dataMonth.longest.buildId}::${dataMonth.longest.buildNumber} (<bs:printTime time="${dataMonth.longest.duration / 1000}"/>)</td>
    <td>${dataMonth.shortest.buildId}::${dataMonth.shortest.buildNumber} (<bs:printTime time="${dataMonth.shortest.duration / 1000}"/>)</td>
  </tr>
  </tbody>
</table>

<h3>Disk usage</h3>
<%--@elvariable id="diskUsage" type="java.util.List<jetbrains.buildServer.serverSide.statistics.diskusage.DiskUsageData>"--%>
<c:forEach items="${diskUsage}" var="du">
  <div>Artifact size: ${du.artifactSize}</div>
  <div>Log size: ${du.logSize}</div>
</c:forEach>




