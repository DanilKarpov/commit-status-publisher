<%@include file="/include-internal.jsp"%>
<style type="text/css">
  li.occurrenceGroup {
    margin-bottom: 5px;
  }

  div.occurrence {
    font-family: monospace;
  }
</style>

<c:choose>
  <c:when test="${not empty errorMessage}">
    <c:out value="${errorMessage}"/>
  </c:when>
  <c:otherwise>
    <jsp:useBean id="usagesBean" type="jetbrains.buildServer.controllers.admin.projects.BuildTypeUsagesBean" scope="request"/>

    <c:set var="editLink"><admin:editBuildTypeLink buildTypeId="${usagesBean.buildType.externalId}"><c:out value="${usagesBean.buildType.name}"/></admin:editBuildTypeLink></c:set>
    <h2 class="noBorder">Build Configuration ${editLink}</h2>

    <div class="usagesSection">
      <c:if test="${usagesBean.numBuildTypesWithInaccessibleSettings gt 0}">
        <div class="attentionComment">
          Note: you do not have permissions to access settings of <strong>${usagesBean.numBuildTypesWithInaccessibleSettings}</strong> build configuration<bs:s val="${usagesBean.numBuildTypesWithInaccessibleSettings}"/>
          which has a dependency on ${editLink}. Please contact administrator to see the complete usages report.
        </div>
      </c:if>
    </div>

    <c:set var="snapshotDependentNum" value="${fn:length(usagesBean.snapshotDependent)}"/>
    <div class="usagesSection">
      <div>
        Used as a snapshot dependency in <strong>${snapshotDependentNum}</strong> build configuration<bs:s val="${snapshotDependentNum}"/><c:if test="${snapshotDependentNum > 0}">:</c:if>
      </div>

      <c:forEach items="${usagesBean.snapshotDependent}" var="bt">
        <ul>
          <authz:authorize anyPermission="EDIT_PROJECT, VIEW_BUILD_CONFIGURATION_SETTINGS" projectId="${bt.projectId}">
          <jsp:attribute name="ifAccessGranted">
            <li><admin:editBuildTypeLinkFull buildType="${bt}" contextProject="${currentProject}"/></li>
          </jsp:attribute>
            <jsp:attribute name="ifAccessDenied">
            <li><c:out value="${bt.fullName}"/></li>
        </jsp:attribute>
          </authz:authorize>
        </ul>
      </c:forEach>
    </div>

    <c:set var="artifactDependentNum" value="${fn:length(usagesBean.artifactDependent)}"/>
    <div class="usagesSection">
      <div>
        Used as an artifact dependency in <strong>${artifactDependentNum}</strong> build configuration<bs:s val="${artifactDependentNum}"/><c:if test="${artifactDependentNum > 0}">:</c:if>
      </div>

      <c:forEach items="${usagesBean.artifactDependent}" var="bt">
        <ul>
          <authz:authorize anyPermission="EDIT_PROJECT, VIEW_BUILD_CONFIGURATION_SETTINGS" projectId="${bt.projectId}">
          <jsp:attribute name="ifAccessGranted">
            <li><admin:editBuildTypeLinkFull buildType="${bt}" contextProject="${currentProject}"/></li>
          </jsp:attribute>
            <jsp:attribute name="ifAccessDenied">
            <li><c:out value="${bt.fullName}"/></li>
        </jsp:attribute>
          </authz:authorize>
        </ul>
      </c:forEach>
    </div>

    <c:set var="btParameterRefsNum" value="${fn:length(usagesBean.usagesViaParameterReferencesFromBuildTypes.keySet())}"/>
    <c:if test="${snapshotDependentNum > 0 or artifactDependentNum > 0}">
      <div class="usagesSection">
        <div>
          <strong>${btParameterRefsNum}</strong> build configuration<bs:s val="${btParameterRefsNum}"/> depending on the <strong><c:out value="${usagesBean.buildType.name}"/></strong>
          <bs:are_is val="${btParameterRefsNum}"/> using parameter references <tt>%dep.${usagesBean.buildType.externalId}.&lt;name>%</tt> in their settings<c:if test="${btParameterRefsNum > 0}">:</c:if>
        </div>

        <c:forEach items="${usagesBean.usagesViaParameterReferencesFromBuildTypes.entrySet()}" var="entry">
          <ul>
            <li>
              <authz:authorize anyPermission="EDIT_PROJECT, VIEW_BUILD_CONFIGURATION_SETTINGS" projectId="${entry.key.projectId}">
          <jsp:attribute name="ifAccessGranted">
            <admin:editBuildTypeLinkFull buildType="${entry.key}" contextProject="${currentProject}"/>
          </jsp:attribute>
                <jsp:attribute name="ifAccessDenied">
            <c:out value="${entry.key.fullName}"/>
        </jsp:attribute>
              </authz:authorize>
              <ul>
                <c:forEach items="${entry.value}" var="group">
                  <li class="occurrenceGroup">
                    <c:out value="${group.description}"/>:
                    <c:forEach items="${group.occurrences}" var="occurrence">
                      <div class="occurrence"><bs:out multilineOnly="true">${occurrence}</bs:out></div>
                    </c:forEach>
                  </li>
                </c:forEach>
              </ul>
            </li>
          </ul>
        </c:forEach>
      </div>
    </c:if>

    <c:set var="tplParameterRefsNum" value="${fn:length(usagesBean.usagesViaParameterReferencesFromTemplates.keySet())}"/>
    <c:if test="${tplParameterRefsNum > 0}">
      <div class="usagesSection">
        <div>
          <strong>${tplParameterRefsNum}</strong> template<bs:s val="${tplParameterRefsNum}"/>
          <bs:are_is val="${tplParameterRefsNum}"/> using parameter references <tt>%dep.${usagesBean.buildType.externalId}.&lt;name>%</tt> in their settings<c:if test="${tplParameterRefsNum > 0}">:</c:if>
        </div>

        <c:forEach items="${usagesBean.usagesViaParameterReferencesFromTemplates.entrySet()}" var="entry">
          <ul>
            <li>
              <authz:authorize anyPermission="EDIT_PROJECT, VIEW_BUILD_CONFIGURATION_SETTINGS" projectId="${entry.key.projectId}">
          <jsp:attribute name="ifAccessGranted">
            <admin:editTemplateLinkFull template="${entry.key}" contextProject="${currentProject}"/>
          </jsp:attribute>
                <jsp:attribute name="ifAccessDenied">
            <c:out value="${entry.key.fullName}"/>
        </jsp:attribute>
              </authz:authorize>
              <ul>
                <c:forEach items="${entry.value}" var="group">
                  <li class="occurrenceGroup">
                    <c:out value="${group.description}"/>:
                    <c:forEach items="${group.occurrences}" var="occurrence">
                      <div class="occurrence"><bs:out multilineOnly="true">${occurrence}</bs:out></div>
                    </c:forEach>
                  </li>
                </c:forEach>
              </ul>
            </li>
          </ul>
        </c:forEach>
      </div>
    </c:if>

    <c:set var="vcsRootParameterRefsNum" value="${fn:length(usagesBean.usagesViaParameterReferencesFromVcsRoots)}"/>
    <c:if test="${vcsRootParameterRefsNum > 0}">
      <div class="usagesSection">
        <div>
          <strong>${vcsRootParameterRefsNum}</strong> VCS root<bs:s val="${vcsRootParameterRefsNum}"/>
          <bs:are_is val="${vcsRootParameterRefsNum}"/> using parameter references <tt>%dep.${usagesBean.buildType.externalId}.&lt;name>%</tt> in their settings<c:if test="${vcsRootParameterRefsNum > 0}">:</c:if>
        </div>

        <c:forEach items="${usagesBean.usagesViaParameterReferencesFromVcsRoots}" var="root">
          <ul>
            <li>
              <authz:authorize anyPermission="EDIT_PROJECT, VIEW_BUILD_CONFIGURATION_SETTINGS" projectId="${root.scope.ownerProjectId}">
          <jsp:attribute name="ifAccessGranted">
            <admin:editVcsRootLink vcsRoot="${root}" editingScope="none" cameFromUrl="${pageUrl}"><c:out value="${root.name}"/></admin:editVcsRootLink>
          </jsp:attribute>
                <jsp:attribute name="ifAccessDenied">
            <c:out value="${root.name}"/>
        </jsp:attribute>
              </authz:authorize>
            </li>
          </ul>
        </c:forEach>
      </div>
    </c:if>

  </c:otherwise>
</c:choose>

