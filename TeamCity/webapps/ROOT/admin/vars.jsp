<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>

<c:set var="pageTitle" value="Server Internal Counters" scope="request"/>

<bs:page>
<jsp:attribute name="head_include">
  <script type="text/javascript">
    BS.Navigation.items = [
        {title: "${pageTitle}", selected:true}
    ];
  </script>
  <style type="text/css">
    .countersData td, .countersData th {
      padding:  2px 1em;
      text-align: left;
    }

    .countersData th {
      background: var(--ring-secondary-background-color, #f7f9fa);
    }

    .countersData td.count {
      text-align: center;
    }

    .countersData td.modified {
      white-space: nowrap;
    }

    .countersData tr:nth-child(even) td {
      background-color: #daffe5;
    }
    .countersData tr:nth-child(odd) td {
      background-color: #f0f0f0;
    }
  </style>
</jsp:attribute>
<jsp:attribute name="body_include">

<table class="countersData">
  <tr>
    <th>Counter name</th>
    <th>Inc for last 1 min</th>
    <th>Inc for last 5 mins</th>
    <th>Inc for last 10 mins</th>
    <th>Last modified</th>
  </tr>
  <c:forEach var="v" items="${vars}">
  <jsp:useBean id="v" type="jetbrains.buildServer.util.Vars"/>
  <tr>
    <td><c:out value="${v.name}"/></td>
    <td class="count">${v.count0}</td>
    <td class="count">${v.count1}</td>
    <td class="count">${v.count2}</td>
    <td class="modified">
      <c:set var="lastModified" value="${v.lastModified}"/>
      <c:choose>
        <c:when test="${empty lastModified}">
          N/A
        </c:when>
        <c:otherwise>
          <bs:date value="${lastModified}" smart="true"/>
        </c:otherwise>
      </c:choose>
    </td>
  </tr>
</c:forEach>
</table>

</jsp:attribute>
</bs:page>
