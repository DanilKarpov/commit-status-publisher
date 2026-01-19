<%@ include file="/include-internal.jsp" %>
<c:choose>
  <c:when test="${not empty buildType and buildType.emptyUuid and showMenuItem}">
    <c:url var="attachUrl" value="/admin/editProject.html?projectId=${buildType.project.externalId}&buildTypeId=${buildType.externalId}&tab=attachBuildHistory"/>
    <a href="${attachUrl}" title="Attach build history...">Attach build history...</a>
  </c:when>
  <c:otherwise>
    <div id="attachBuildHistoryPlaceholder"></div>
    <script type="text/javascript">
      $j('#attachBuildHistoryPlaceholder').parent().hide();
    </script>
  </c:otherwise>
</c:choose>
