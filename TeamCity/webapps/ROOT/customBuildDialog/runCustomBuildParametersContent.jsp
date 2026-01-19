<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="group" type="jetbrains.buildServer.controllers.RunBuildParameterGroup" scope="request"/>
<c:url var="refreshUrl" value="/runCustomBuild.html"/>

<tr id="${group.headerId}">
  <th colspan="3"><c:out value="${group.sectionName}"/></th>
</tr>
<c:if test="${group.parametersAvailable}">
  <script type="text/javascript">
    $j('#${group.headerId}').hide();
  </script>
</c:if>
<tbody id="${group.bodyId}">
<c:forEach items="${group.parameterInfos}" var="p">
  <c:set var="safeName"><c:out value="${p.name}" /></c:set>
  <c:choose>
    <c:when test="${p.newParameter}">
      <tr class="modifiedParam">
        <td class="paramName">
          <forms:textField name="name" value="${p.name}" style="width: 100%"/>
        </td>
        <td class="paramValue">
          <div class="completionIconWrapper">
              <%-- assume here new parameters have no custom type --%>
            <forms:textField expandable="true" style="width: 100%;" name="value" id="${p.id}"
                             value="${p.parameter.value}"
                             className="buildTypeParams"/>
          </div>
        </td>
        <td class="edit">
          <a href="#" onclick="BS.RunBuildDialog.removeParameter(this.parentNode.parentNode); return false;">Delete</a>
        </td>
      </tr>
    </c:when>


    <c:otherwise>
      <c:set var="pp" value="${p.defaultParameterInfo}"/>
      <c:set var="modifiedClass"><c:if test="${pp.modified}">modifiedParam</c:if></c:set>
      <tr class="${modifiedClass}">
        <td class="paramName">
          <label class="paramName__label" for="${p.id}" title="parameter name: ${safeName}"><bs:trim maxlength="45">${p.label}</bs:trim><c:if test="${p.required}"><l:star/></c:if></label>
          <input type="hidden" name="${p.parameterMarker}" value="${safeName}"/>
          <input type="hidden" name="customParameterNames" value="${safeName}"/>
        </td>
        <td class="paramValue">
          <div id="container_${p.id}_div">
          <bs:refreshable containerId="refresh_container_${p.id}_div" pageUrl="${refreshUrl}">
          <div class="completionIconWrapper">
            <c:set var="jsObject">BS.RunBuildDialog.CustomControls['<bs:forJs>${p.id}</bs:forJs>']</c:set>
            <c:set var="isCustom" value="${not empty p.parameter.controlDescription}"/>
            <script type="text/javascript">
              ${jsObject} = BS.RunBuildDialog.getAddControlFunction('container_${p.id}_div', '${p.id}');
            </script>
            <c:choose>
              <c:when test="${isCustom}">
                <ext:typedParameter context="${pp.renderContext}" js="${jsObject}"/>
              </c:when>
              <c:otherwise>
                <forms:textField expandable="true" style="width: 100%;" name="${p.id}" id="${p.id}" value="${p.parameter.value}" className="buildTypeParams"/>
              </c:otherwise>
            </c:choose>
          </div>
          <c:if test="${not empty p.description}"><span class="smallNote"><bs:out value="${p.description}"/></span></c:if>
          <span class="error" id="error_${p.id}"></span>
          </bs:refreshable>
          </div>
        </td>
        <td class="edit">
          <a href="#" <c:if test="${p.readonly}">style="display: none"</c:if> id="reset_${p.id}" onclick="BS.RunBuildDialog.resetParameter('${p.id}'); return false;">Reset</a>
        </td>
      </tr>
      <c:if test="${pp.modified}">
        <script type="text/javascript">
          BS.RunBuildDialog.setParameterHighlightStatus("container_${p.id}_div", true);
        </script>
      </c:if>
    </c:otherwise>
  </c:choose>
</c:forEach>
</tbody>