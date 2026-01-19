<%@include file="/include-internal.jsp"%>
<jsp:useBean id="vcsRoots" type="java.util.List" scope="request"/>
<jsp:useBean id="showUseButton" type="java.lang.Boolean" scope="request"/>
<c:set var="cameFromUrl" value="${param['cameFromUrl']}"/>
<p>The following VCS roots have similar settings:</p>

<table class="duplicateVcsRootsTable">
  <c:forEach items="${vcsRoots}" var="vcsRoot" varStatus="pos">
    <tr>
      <c:if test="${showUseButton}">
        <td style="width: 8%" class="edit ${pos.last ? 'last' : ''}">
          <input class="btn btn_mini" type="button" value="Use this" onclick="BS.DuplicateVcsRootsDialog._useSelectedVcsRoot('${vcsRoot.externalId}')"/>
        </td>
      </c:if>
      <td class="${pos.last ? 'last' : ''}">
        <admin:vcsRootName vcsRoot="${vcsRoot}" editingScope="none" cameFromUrl="${cameFromUrl}"/><br/>
        belongs to <admin:projectName project="${vcsRoot.project}"/>,

        <c:set var="usages" value="${vcsRoot.usages}"/>
        <c:if test="${not empty usages}">
        <bs:popup_static controlId="rootUsages_${vcsRoot.id}" popup_options="shift: {x: -100, y: 20}, width: '10em', className: 'quickLinksMenuPopup'">
          <jsp:attribute name="content">
            <div>
              <ul class="menuList">
                <c:forEach items="${usages}" var="usage">
                  <c:set var="buildType" value="${usage.key}"/>
                  <l:li>
                    <authz:authorize allPermissions="EDIT_PROJECT" projectId="${buildType.projectId}">
                      <jsp:attribute name="ifAccessGranted">
                        <admin:editBuildTypeLink step="vcsRoots" buildTypeId="${buildType.externalId}" cameFromUrl="${cameFromUrl}"><c:out value="${buildType.fullName}"/></admin:editBuildTypeLink>
                      </jsp:attribute>
                      <jsp:attribute name="ifAccessDenied">
                        <c:out value="${buildType.fullName}"/>
                      </jsp:attribute>
                    </authz:authorize>
                  </l:li>
                </c:forEach>
              </ul>
            </div>
          </jsp:attribute>
          <jsp:body>
            used in <strong>${fn:length(usages)}</strong> build configuration<bs:s val="${fn:length(usages)}"/>
          </jsp:body>
        </bs:popup_static>
        </c:if>
      </td>
    </tr>
  </c:forEach>
</table>
