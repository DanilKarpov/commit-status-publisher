<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="auditLogData" scope="request" type="jetbrains.buildServer.controllers.audit.AuditLogData"/>
<c:set var="currentTab" value="" scope="request"/>

<bs:refreshable containerId="auditLogContainer" pageUrl="${pageUrl}">
  <jsp:include page="/admin/auditFilter.jsp"/>
  <c:choose>
    <c:when test="${fn:length(auditLogData.actions) > 0}">
      <table class="borderBottom auditLog">
        <tr>
          <th>Date</th>
          <th>User</th>
          <th>Action</th>
          <th>Comment</th>
        </tr>
        <c:forEach items="${auditLogData.actions}" var="auditLogAction">
          <tr>
            <td class="date"><bs:date value="${auditLogAction.timestamp}"/></td>
            <td class="user">
              <admin:auditLogActionUserName auditLogAction="${auditLogAction}"/>
            </td>
            <td>
              <div style="max-width: 480px">
                <c:set var="_actionId" value="${auditLogAction.comment.commentId}" scope="request"/>
                <c:set var="description" value="${auditLogAction.actionDescription}"/>
                <c:forEach items="${auditLogAction.objects}" var="wrapper" varStatus="status">
                  <c:set var="_object" value="${wrapper.object}" scope="request"/>
                  <c:set var="_objectId" value="${wrapper.objectId}" scope="request"/>
                  <c:set var="description"><bs:format source="${description}" key="${status.index}">
                    <jsp:attribute name="replacement"><jsp:include page="/admin/auditObjectLinks/${wrapper.linkPage}"/></jsp:attribute>
                  </bs:format></c:set>
                </c:forEach>
                  ${description}
              </div>
            </td>
            <c:set var="commentText" value="${auditLogAction.commentText}"/>
            <td><c:choose><c:when test="${commentText != null && not empty commentText}"><bs:out value="${commentText}"/></c:when><c:otherwise>&nbsp;</c:otherwise></c:choose></td>
          </tr>
        </c:forEach>
      </table>
    </c:when>
    <c:otherwise>
      <div>No audit data found for the specified filters</div>
    </c:otherwise>
  </c:choose>

  <c:set var="urlPattern"><c:url value="/admin/admin.html?item=audit&keepSession=1&page=[page]"/></c:set>
  <bs:pager place="bottom" urlPattern="${urlPattern}" pager="${auditLogData.pager}"/>
</bs:refreshable>
