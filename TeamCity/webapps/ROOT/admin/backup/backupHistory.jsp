<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>

<jsp:useBean id="current" type="jetbrains.buildServer.controllers.admin.backup.BackupCurrentInfo" scope="request"/>
<jsp:useBean id="history" type="jetbrains.buildServer.serverSide.maintenance.BackupHistory" scope="request"/>

<div id="container">

  <c:set var="numRecords" value="${history.pager.totalRecords}"/>
  <c:if test="${numRecords == 0}">
    <p>There are no backup records in the history.</p>
  </c:if>
  <c:if test="${numRecords > 0}">
    <p>There <bs:are_is val="${numRecords}"/> <strong>${numRecords}</strong> backup record<bs:s val="${numRecords}"/> in the history.</p>

    <table class="dark borderBottom">
      <thead>
        <tr>
          <th>Status</th>
          <th>File</th>
          <th>Started</th>
          <th>Finished</th>
          <th>Size</th>
        </tr>
      </thead>

      <c:forEach var="record" items="${history.records}">
        <tr>

          <td align="center">
            <c:choose>
              <c:when test="${record.inProgress}">
                <c:if test="${current.processId == record.id}"> <b>In progress</b> </c:if>
                <c:if test="${current.processId != record.id}"> &nbsp; </c:if>
              </c:when>
              <c:when test="${record.cancelledOrCancelling}">
                <span style="color:gray">Canceled</span>
              </c:when>
              <c:when test="${record.finished}">
                <span style="color:#4da400">OK</span>
              </c:when>
              <c:when test="${record.fault}">
                <span style="color:#a90f1a">Failed</span>
              </c:when>
              <c:otherwise>
                &nbsp;
              </c:otherwise>
            </c:choose>
          </td>

          <td>
            <c:if test="${record.fileExists}">
              <a href="<c:url value='${record.downloadUrl}'/>"><bs:makeBreakable text="${record.name}" regex=".{60}"/></a>
            </c:if>
            <c:if test="${not record.fileExists}">
              <bs:makeBreakable text="${record.name}" regex=".{60}"/>
            </c:if>
          </td>

          <td>
            <bs:date value="${record.startTimestamp}"/>
          </td>

          <td>
            <c:if test="${record.finished}">
              <bs:date value="${record.finishTimestamp}"/>
            </c:if>
            <c:if test="${not record.finished}">
              &nbsp;
            </c:if>
          </td>

          <td>
            <c:if test="${record.finished and record.fileSize > 0}">
              <span title="${record.fileSize} bytes">${record.formattedSize}</span>
            </c:if>
            <c:if test="${not (record.finished and record.fileSize > 0)}">
              &nbsp;
            </c:if>
          </td>

        </tr>
      </c:forEach>

    </table>

    <c:if test="${history.pager.pageCount >= 2}">
      <c:set var="pagerUrlPattern" value="admin.html?item=backup&tab=backupHistory&page=[page]"/>
      <bs:pager place="bottom" urlPattern="${pagerUrlPattern}" pager="${history.pager}"/>
    </c:if>

  </c:if>

</div>

