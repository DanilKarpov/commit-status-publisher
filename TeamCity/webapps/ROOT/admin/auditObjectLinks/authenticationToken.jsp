<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<jsp:useBean id="_object" scope="request" type="jetbrains.buildServer.serverSide.impl.audit.finders.AuthenticationTokenAuditFinder.AuthenticationTokenAuditItem"/>
<jsp:useBean id="_objectId" scope="request" type="java.lang.String"/>
<c:choose>
  <c:when test="${not empty _object}">
    <c:out value="\"${_object.name}\""/> with expiration set to
    <c:choose>
      <c:when test="${_object.expirySet}">"<bs:date value="${_object.expirationTime}"/>"</c:when>
      <c:otherwise>"no expiration"</c:otherwise>
    </c:choose>

    <c:if test="${_object.restricted}">
      <span id="showAuthenticationTokenPermissions_${_objectId}">(<a action="#" style="cursor: pointer">show scope</a>)</span>
      <div id="authenticationTokenPermissions_${_objectId}" style="display: none">
        <ul>
          <c:forEach var="roleScopeToPermissions" items="${_object.permissionsRestriction.permissions}">
            <li style="">
              <c:set var="roleScope" value="${roleScopeToPermissions.key}"/>
              <c:set var="permissions" value="${roleScopeToPermissions.value.toList()}"/>
              <c:choose>
                <c:when test="${_object.isProjectAccessibleByContextUser(roleScope)}">
                  <c:choose>
                    <c:when test="${roleScope.global}">
                      Global
                    </c:when>
                    <c:otherwise>
                      <c:set var="project" value="${_object.getProjectIfAccessible(roleScope)}"/>
                      <c:choose>
                        <c:when test="${not empty project}">
                          <bs:projectLink project="${project}"/>:
                        </c:when>
                        <c:otherwise>
                          Inaccessible project &lt;<c:out value="${roleScope.projectId}"/>&gt;:
                        </c:otherwise>
                      </c:choose>
                    </c:otherwise>
                  </c:choose>
                  <ul>
                    <c:forEach var="permission" items="permissions">
                      <c:forEach var="permission" items="${permissions}">
                        <li class="accessTokenPermissionItem">${permission.description}</li>
                      </c:forEach>
                    </c:forEach>
                  </ul>
                </c:when>
                <c:otherwise>
                  &lt;Inaccessible project&gt;
                </c:otherwise>
              </c:choose>
            </li>
          </c:forEach>
        </ul>
      </div>
      <script type="application/javascript">
        $j('#showAuthenticationTokenPermissions_${_objectId}').click(function () {
          $j('#showAuthenticationTokenPermissions_${_objectId}').hide();
          $j('#authenticationTokenPermissions_${_objectId}').show();
        });
      </script>
    </c:if>
  </c:when>
  <c:otherwise>
    <c:out value="\"${_objectId}\""/>
  </c:otherwise>
</c:choose>