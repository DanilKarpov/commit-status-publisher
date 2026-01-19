<%@ include file="/include-internal.jsp" %>
<%--@elvariable id="problem" type="jetbrains.buildServer.web.proxyProblems.ProxyServerConfigurationCheckController.Problem"--%>

<table class="runnerFormTable" style="margin-top: 1em">
  <tr class="groupingTitle">
    <td>Overall Status</td>
  </tr>
  <tr>
    <td>
      <c:choose>
        <c:when test="${problem == null}">
          <div style="color: #0c7523">Proxy configuration is correct</div>
          <div>Note that there still can be proxy-related configuration errors when TeamCity is accessed from another browser or through another proxy.</div>
        </c:when>
        <c:otherwise>
          <div style="color: #a90f1a">Proxy configuration errors are detected.</div>
        </c:otherwise>
      </c:choose>
    </td>
  </tr>

  <c:if test="${problem != null}">
    <tr class="groupingTitle">
      <td>Problem Description</td>
    </tr>
    <tr>
      <td>
          ${problem.type}<c:if test="${problem.publicDetails != null}">: <c:out value="${problem.publicDetails}"/> </c:if>

          <div style="margin-top: 0.5em;">
            <authz:authorize allPermissions="CHANGE_SERVER_SETTINGS">
                  <jsp:attribute name="ifAccessGranted">
                    Details: <c:out value="${problem.adminDetails}"/><br/>
                    Ensure that the proxy server is configured as described in the <bs:helpLink file="Configuring+Proxy+Server">documentation</bs:helpLink>.
                  </jsp:attribute>
              <jsp:attribute name="ifAccessDenied">
                    Contact your system administrator for the details.
                  </jsp:attribute>
            </authz:authorize>
          </div>
      </td>
    </tr>
  </c:if>
</table>

<div style="margin-top: 1em;">
  <a href="#" onclick="return BS.reload(true);">Refresh</a>
</div>




