<%@ page import="jetbrains.buildServer.web.util.SessionUser" %>
<%@ page import="jetbrains.buildServer.users.SUser" %>
<%@ include file="include-internal.jsp" %>

<%@ taglib prefix="bs" tagdir="/WEB-INF/tags/" %>
<%--@elvariable id="bean" type="jetbrains.buildServer.controllers.BasePropertiesBean"--%>
<jsp:useBean id="packages" scope="request" type="java.util.List<jetbrains.buildServer.controllers.agent.AgentDistributionsController.DistrInfo>"/>
<jsp:useBean id="defaultPackage" scope="request" type="java.lang.String"/>
<jsp:useBean id="serverTC" type="jetbrains.buildServer.serverSide.SBuildServer" scope="request"/>

<bs:page>
  <jsp:attribute name="page_title">Agent distributions</jsp:attribute>

  <jsp:attribute name="head_include">

    <bs:linkCSS>
      /css/admin/adminMain.css
    </bs:linkCSS>

    <style type="text/css">
      .agentBundles {
        text-align: left;
      }
      .agentBundles th {
        font-weight: normal;
        font-size: 80%;
        color: #737577;
        padding-left: 1em;
      }
    </style>

  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div id="agentDistributionsSection">
      <h2>Agent Distributions</h2>
      <bs:smallNote>
        This page allows you to download custom TeamCity agent distributions bundled with JDK versions<authz:authorize allPermissions="CHANGE_SERVER_SETTINGS">
        uploaded via the <a id="settingsLink" href="admin/admin.html?item=includedJdkTab">Agent JDKs</a> page </authz:authorize> and/or plugins.
        <br/>Distributions with JDKs allow you to install agents and Java they require in one go.
      </bs:smallNote>
      <br/>
      <div>
        <h3>Agent Distributions with JDK</h3>
        <table class="settings agentBundles" style="width: 80%;">
        <tr>
          <th>
            Plugins <bs:helpIcon iconTitle="Agents without plugins take more time to start for the first time since they download these missing components">            </bs:helpIcon>
          </th>
          <th>OS</th>
          <th>Architecture</th>
          <th>JDK Version</th>
          <th>Type</th>
          <th>Download link</th>
        </tr>
        <c:forEach var="pkg" items="${packages}">
          <tr>
            <td>${pkg.pluginsIncluded ? "Included" : "Not included"}</td>
            <td>${pkg.os}</td>
            <td>${pkg.arch}</td>
            <td>${pkg.version}</td>
            <td>${pkg.type}</td>
            <td>
              <c:choose>
                <c:when test="${pkg.url != null}">
                      <a id="${pkg.os}${pkg.arch}_url" href="<c:url value='${pkg.url}'/>"><c:out value="${serverTC.rootUrl}${pkg.url}"/></a>
                     <span class="clipboard-btn tc-icon icon16 tc-icon_copy"  style="float:right" data-clipboard-action="copy" data-clipboard-target="#${pkg.os}${pkg.arch}_url"></span>
                </c:when>
                <c:otherwise>
                  ${pkg.status}
                </c:otherwise>
              </c:choose>
            </td>
          </tr>
        </c:forEach>
      </table>
      </div>
      <br/>
      <div>
        <h3>OS-independent agent distributions</h3>
        <table class="settings agentBundles" style="width: 80%;">
          <tr>
            <th>Type</th>
            <th>Description</th>
            <th>Download link</th>
          </tr>
          <tr>
            <td>zip</td>
            <td>The base agent distribution.</td>
            <td>
              <a id="minDistrUrl" href="<c:url value='/update/buildAgent.zip'/>"><c:out value="${serverTC.rootUrl}/update/buildAgent.zip"/></a>
              <span class="clipboard-btn tc-icon icon16 tc-icon_copy"  style="float:right" data-clipboard-action="copy" data-clipboard-target="#minDistrUrl"></span>
            </td>
          </tr>
          <tr>
            <td>zip</td>
            <td>The full agent distribution with all plugins available on the server.</td>
            <td>
              <a id="fullDistrUrl" href="<c:url value='/update/buildAgentFull.zip'/>"><c:out value="${serverTC.rootUrl}/update/buildAgentFull.zip"/></a>
              <span class="clipboard-btn tc-icon icon16 tc-icon_copy"  style="float:right" data-clipboard-action="copy" data-clipboard-target="#fullDistrUrl"></span>
            </td>
          </tr>
          <tr>
            <td>docker image</td>
            <td>The base agent distribution.</td>
            <td>
              <a id="fullDockerUrl"  href="https://hub.docker.com/r/jetbrains/teamcity-minimal-agent/" target=�_blank�><c:out value="https://hub.docker.com/r/jetbrains/teamcity-minimal-agent/"/></a>
              <span class="clipboard-btn tc-icon icon16 tc-icon_copy"  style="float:right" data-clipboard-action="copy" data-clipboard-target="#fullDockerUrl"></span>
            </td>
          </tr>
          <tr>
            <td>docker image</td>
            <td>The base agent distribution with additional applications and building tools (Git, Mercurial, Docker, and so on). <bs:helpIcon iconTitle="See the linked page to learn more about the installed components"/></td>
            <td>
              <a id="minDockerUrl"  href="https://hub.docker.com/r/jetbrains/teamcity-agent/" target=�_blank�><c:out value="https://hub.docker.com/r/jetbrains/teamcity-agent/"/></a>
              <span class="clipboard-btn tc-icon icon16 tc-icon_copy"  style="float:right" data-clipboard-action="copy" data-clipboard-target="#minDockerUrl"></span>
            </td>
          </tr>
        </table>
      </div>
      <script type="text/javascript">
        BS.Clipboard('.clipboard-btn');
      </script>
    </div>
  </jsp:attribute>
</bs:page>