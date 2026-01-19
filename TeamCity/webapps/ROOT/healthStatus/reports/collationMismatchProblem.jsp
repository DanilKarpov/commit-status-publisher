<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="healthStatusItem"
             type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem"
             scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>

<c:set var="problem" value="${healthStatusItem.additionalData['problem']}" scope="request"/>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>

  Configuration issue found in the TeamCity database schema: tables have different collations.
  <c:url value="/admin/admin.html?item=healthStatus#selectedCategoryId=CollationMismatch" var="hrp"/>
  <span name="reference-to-collation-mismatch-info">See the <a href="${hrp}">health report page</a>.</span>

<div class="full-health-item" style="display: ${showMode == inplaceMode ? 'none' : ''}">
  <p>The default database collation is <b><c:out value="${problem.databaseCollation}"/></b>.</p>
  <div>
    The following tables and/or columns have other collations:
    <table class="health-report-mini-table">
      <tr>
        <th align="left">Table.Column</th> <th align="left">Current Collation</th>
      </tr>
      <c:forEach var="entry" items="${problem.wrongColumns}">
        <tr>
          <td align="left"><c:out value="${entry.key}"/></td> <td align="left"><c:out value="${entry.value}"/></td>
        </tr>
      </c:forEach>
    </table>
  </div>
  <p>
    It might cause collation-related SQL errors affecting TeamCity functionality or one of the next upgrades.
  </p>
  <p>
    For the resolution instructions refer to the <bs:helpLink file="Common+Problems" anchor="Characterset%2Fcollationmismatch">documentation</bs:helpLink>.
  </p>
</div>

<c:if test="${showMode != inplaceMode}">
  <script type="text/javascript">
    jQuery("[name=reference-to-collation-mismatch-info]").hide();
  </script>
</c:if>
