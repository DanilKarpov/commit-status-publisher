<%@include file="/include-internal.jsp"%>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterRenderContext"/>
<jsp:useBean id="options" scope="request" type="java.util.Collection< jetbrains.buildServer.controllers.parameters.types.SelectParameterTypeBase.KeyValue >"/>
<jsp:useBean id="valueSeparator" scope="request" type="java.lang.String"/>

<c:set var="containerId" value="custom_control_${context.id}_container"/>

<input type="hidden" name="${context.id}" id="${context.id}" value="<c:out value='${context.parameter.value}'/>" />
<div id="${containerId}" style="width: 100%">
  <c:if test="${fn:length(options) > 5}">
  <div><a href="#" onclick="$j(BS.Util.escapeId('${containerId}')).get(0).selectAll(); return false;">All</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="#" onclick="$j(BS.Util.escapeId('${containerId}')).get(0).unselectAll(); return false;">None</a></div>
  </c:if>
  <c:forEach var="it" items="${options}" varStatus="vs">
    <div>
      <c:set var="cbId" value="mcb_${containerId}_${vs.index}"/>
      <c:set var="preparedVal"><c:out value="${it.key}"/></c:set>
      <forms:checkbox disabled="${context.readOnly}" name="" id="${cbId}" value="${preparedVal}" style="vertical-align:middle; margin:0; padding:0; width: auto;"/>
      <label for="${cbId}"><c:out value="${it.value}"/></label>
    </div>
  </c:forEach>
</div>

<script type="text/javascript">
    (function($) {
      var sep = '${util:forJS(valueSeparator, true , false)}';

      var selectRoot = function() { return $(BS.Util.escapeId("${containerId}")); };
      var selectVal = function() { return $(BS.Util.escapeId("${context.id}")); };

      var updateFromCheckboxes = function() {
        var checked = selectRoot().find("input:checked");

        var str = "";
        checked.each(function () {
          if (str.length != 0) str += sep;
          str += $(this).val();
        });
        selectVal().val(str);
      };

      var updateToCheckboxes = function() {
        var selectedSet = {};
        selectVal().val().split(sep).each( function(v,i) { selectedSet[v] = v; });

        selectRoot().find("input[type='checkbox']").each(function() {
          var attr = $(this).val();
          var selected = !!selectedSet[attr];
          $(this).prop('checked', selected);
        })
      };

      selectRoot().get(0).selectAll = function() {
        selectRoot().find("input[type='checkbox']").prop('checked', true);
        updateFromCheckboxes();
      };

      selectRoot().get(0).unselectAll = function() {
        selectRoot().find("input[type='checkbox']").prop('checked', false);
        updateFromCheckboxes();
      };

      selectRoot().find("input[type='checkbox']").change(updateFromCheckboxes);
      selectVal().change(updateToCheckboxes);

      updateToCheckboxes();

    })(jQuery);
</script>
